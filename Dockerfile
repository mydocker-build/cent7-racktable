## Modified by Sam KUON - 28/05/17
FROM centos:latest
MAINTAINER Sam KUON "sam.kuonssp@gmail.com"

# System timezone
ENV TZ=Asia/Phnom_Penh
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Env
ENV RT_VER 0.21.1

# Repositories and packages
RUN yum -y install epel-release && \
	curl -s https://setup.ius.io/ | bash

RUN yum -y update && \
    yum -y install \
	php72u \
	php72u-mysqlnd \
	php72u-pdo \
	php72u-gd \
	php72u-mbstring \
	php72u-bcmath \
	php72u-json \
	php72u-ldap \
	php72u-snmp \
	php72u-common \
	wget \
	httpd &&\
    yum clean all && rm -rf /var/cache/yum

# Set Timzone in PHP and session
RUN sed -i "s/^;date.timezone =$/date.timezone = \"Asia\/Phnom_Penh\"/" /etc/php.ini
RUN sed -i "s/^session.gc_maxlifetime = 1440/session.gc_maxlifetime = 14400/" /etc/php.ini

# Secure Apache server
## Disable CentOS Welcome Page
RUN sed -i 's/^\([^#]\)/#\1/g' /etc/httpd/conf.d/welcome.conf

## Turn off directory listing, Disable Apache's FollowSymLinks, Turn off server-side includes (SSI) and CGI execution
RUN sed -i 's/^\([^#]*\)Options Indexes FollowSymLinks/\1Options -Indexes +SymLinksifOwnerMatch -ExecCGI -Includes/g' /etc/httpd/conf/httpd.conf

## Hide the Apache version, secure from clickjacking attacks, disable ETag, secure from XSS attacks and protect cookies with HTTPOnly flag
RUN echo $'\n\
ServerSignature Off\n\
ServerTokens Prod\n\
Header append X-FRAME-OPTIONS "SAMEORIGIN"\n\
FileETag None\n\
<IfModule mod_headers.c>\n\
    Header set X-XSS-Protection "1; mode=block"\n\
</IfModule>\n'\
>> /etc/httpd/conf/httpd.conf

# Disable unnecessary modules in /etc/httpd/conf.modules.d/00-base.conf
RUN sed -i '/mod_cache.so/ s/^/#/' /etc/httpd/conf.modules.d/00-base.conf && \
    sed -i '/mod_cache_disk.so/ s/^/#/' /etc/httpd/conf.modules.d/00-base.conf && \
    sed -i '/mod_substitute.so/ s/^/#/' /etc/httpd/conf.modules.d/00-base.conf && \
    sed -i '/mod_userdir.so/ s/^/#/' /etc/httpd/conf.modules.d/00-base.conf

# Disable everything in /etc/httpd/conf.modules.d/00-dav.conf, 00-lua.conf, 00-proxy.conf and 01-cgi.conf
RUN sed -i 's/^/#/g' /etc/httpd/conf.modules.d/00-dav.conf && \
    sed -i 's/^/#/g' /etc/httpd/conf.modules.d/00-lua.conf && \
    sed -i 's/^/#/g' /etc/httpd/conf.modules.d/00-proxy.conf && \
    sed -i 's/^/#/g' /etc/httpd/conf.modules.d/01-cgi.conf

# Download Racktables
RUN cd /tmp/ && wget https://sourceforge.net/projects/racktables/files/RackTables-$RT_VER.tar.gz && \
    tar -xzvf RackTables-$RT_VER.tar.gz -C /usr/src/ && \
    rm -rf /tmp/*

# Copy run-httpd script to image
ADD ./conf.d/run-httpd.sh /run-httpd.sh
ADD ./conf.d/apache_state.conf /etc/httpd/conf.d/apache_state.conf
RUN chmod -v +x /run-httpd.sh

EXPOSE 80 443

CMD ["/run-httpd.sh"]

