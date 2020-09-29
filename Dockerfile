FROM ubuntu:20.04 as compile-image

LABEL maintainer="Paul Asadoorian <paul@psw.io>"

#
# Install all required packages and system dependencies
#
RUN set -eux; \
    apt-get update; \
	apt-get install -y --no-install-recommends \
	wget \
	build-essential \
	libpcre3 \
	libpcre3-dev \
	zlib1g \
	zlib1g-dev \
	libssl-dev \
	unzip \
	# for envsubst
	gettext-base \
	; \
	rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/nginx

RUN set -eux; \
    wget --no-check-certificate https://github.com/sergey-dryabzhinsky/nginx-rtmp-module/archive/dev.zip; \
    wget --no-check-certificate http://nginx.org/download/nginx-1.18.0.tar.gz

RUN set -eux; \
    tar -zxvf nginx-1.18.0.tar.gz; \
    unzip dev.zip; \
    cd nginx-1.18.0; \
    ./configure --with-http_ssl_module --with-stream_ssl_module --with-stream --add-module=../nginx-rtmp-module-dev; \
    make; \
    make install

FROM ubuntu:20.04 as build-image

COPY --from=compile-image /usr/local/nginx /usr/local/nginx

RUN set -eux; \
    apt-get update; \
	apt-get install -y --no-install-recommends \
	# required to obtain the SSL libraries
	libssl-dev \
	# for envsubst
	gettext-base \
	; \
	rm -rf /var/lib/apt/lists/*

#
# Copy over our Nginx config files
#
RUN mkdir /etc/nginx
COPY ./conf/nginx/nginx.conf /etc/nginx/nginx.conf
COPY conf/nginx/nginx-rtmp.template /etc/nginx
COPY conf/nginx/nginx-http.template /etc/nginx
COPY conf/nginx/nginx-https.template /etc/nginx
RUN mkdir -p /etc/ssl/live
COPY conf/ssl/fullchain.pem /etc/ssl/live/
COPY conf/ssl/privkey.pem /etc/ssl/live/
RUN mkdir -p /var/www/html
COPY conf/nginx/index.html /var/www/html/

#
# Add nginx user and set permissions
#
RUN mkdir -p /etc/nginx/conf.d
ENV chownlist "/usr/local/nginx /etc/nginx /var/run/nginx.pid /etc/ssl/live /var/www/html"
RUN useradd -r -U -u 1001 www && \
    touch /var/run/nginx.pid && \
    chown -R www:www ${chownlist}

#
# Copy over the startup script that will use the template to start NGINX
#
COPY start.sh /start.sh
RUN chmod +x /start.sh

#
# Drop user privs and run NGINX
#
USER www
CMD ["/start.sh"]
