FROM drupal:8.5-apache

# We use imagemagick to support behat screenshots
RUN apt-get update && apt-get install -y \
  git \
  imagemagick \
  libmagickwand-dev \
  mariadb-client \
  rsync \
  sudo \
  unzip \
  vim \
  wget \
  sqlite3 \
  fontconfig \
  && docker-php-ext-install mysqli \
  && docker-php-ext-install pdo \
  && docker-php-ext-install pdo_mysql

# Install XDebug.
RUN pecl install xdebug-2.6.0 \
    && docker-php-ext-enable xdebug

# Install ImageMagic to take screenshots.
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install composer.
RUN wget https://raw.githubusercontent.com/composer/getcomposer.org/f3333f3bc20ab8334f7f3dada808b8dfbfc46088/web/installer -O - -q | php -- --quiet
RUN mv composer.phar /usr/local/bin/composer

# Put a turbo on composer.
RUN composer global require hirak/prestissimo

# Install Robo CI.
# @TODO replace the following URL by http://robo.li/robo.phar when the Robo team fixes it.
RUN wget https://github.com/consolidation/Robo/releases/download/1.2.2/robo.phar
RUN chmod +x robo.phar && mv robo.phar /usr/local/bin/robo

# php-dom and bcmath dependencies
RUN apt-get install -y libxslt-dev \
    && docker-php-ext-install bcmath xsl

# Cache currently used libraries to improve build times. We need to force
# discarding changes as Drupal removes test code in /vendor.
RUN cd /var/www/html \
    # && cp composer.json composer.json.original \
    # && cp composer.lock composer.lock.original \
    && composer require --dev \
        cweagans/composer-patches \
        behat/mink-selenium2-driver \
        behat/mink-extension:v2.2 \
        drupal/coder \
        dealerdirect/phpcodesniffer-composer-installer \
        drupal/drupal-extension:master-dev \
        bex/behat-screenshot \
        phpmd/phpmd \
        phpmetrics/phpmetrics \
    # && mv composer.json.original composer.json \
    # && mv composer.lock.original composer.lock \
    # && COMPOSER_DISCARD_CHANGES=1 composer install
    && COMPOSER_DISCARD_CHANGES=1 composer update

COPY hooks/* /var/www/html/

# Commit our preinstalled Drupal database for faster Behat tests.
COPY drupal.sql.gz /var/www
COPY settings.php /var/www/html/sites/default/
RUN mkdir -p /var/www/html/sites/default/files/config_yt3arM1I65-zRJQc52H_nu_xyV-c4YyQ86uwM1E3JBCvD3CXL38O8JqAxqnWWj8rHRiigYrj0w/sync \
    && chown -Rv www-data /var/www/html/sites/default/files

# Patch Drupal to avoid a bug where behat failures show as passes.
# https://www.drupal.org/project/drupal/issues/2927012#comment-12467957
RUN cd /var/www/html \
    && curl https://www.drupal.org/files/issues/2927012.22-log-error-exit-code.patch | patch -p1

# Add the vendor/bin directory to the $PATH
ENV PATH="/var/www/html/vendor/bin:${PATH}"

# We need to expose port 80 for phantomjs containers.
EXPOSE 80
