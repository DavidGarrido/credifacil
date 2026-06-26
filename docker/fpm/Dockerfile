FROM sail-8.4/app

USER root

RUN apt-get update && apt-get install -y nginx php8.4-fpm && apt-get clean && rm -rf /var/lib/apt/lists/*

COPY docker/fpm/nginx-default.conf /etc/nginx/sites-enabled/default
COPY docker/fpm/supervisord-fpm.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /var/log/nginx /var/run/php && \
    sed -i "s/user = www-data/user = sail/g" /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i "s/group = www-data/group = sail/g" /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i "s/listen.owner = www-data/listen.owner = sail/g" /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i "s/listen.group = www-data/listen.group = sail/g" /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i "s/pm.max_children = 5/pm.max_children = 20/g" /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i "s/pm.start_servers = 2/pm.start_servers = 4/g" /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i "s/pm.min_spare_servers = 1/pm.min_spare_servers = 2/g" /etc/php/8.4/fpm/pool.d/www.conf && \
    sed -i "s/pm.max_spare_servers = 3/pm.max_spare_servers = 8/g" /etc/php/8.4/fpm/pool.d/www.conf

RUN echo "opcache.enable=1" >> /etc/php/8.4/cli/conf.d/99-sail.ini && \
    echo "opcache.memory_consumption=128" >> /etc/php/8.4/cli/conf.d/99-sail.ini && \
    echo "opcache.max_accelerated_files=10000" >> /etc/php/8.4/cli/conf.d/99-sail.ini && \
    cp /etc/php/8.4/cli/conf.d/99-sail.ini /etc/php/8.4/fpm/conf.d/99-sail.ini

ENV SUPERVISOR_PHP_COMMAND=""
ENV SUPERVISOR_PHP_USER="sail"

EXPOSE 80/tcp

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
