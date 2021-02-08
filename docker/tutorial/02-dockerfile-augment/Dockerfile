# build from base image
FROM nginx:latest
RUN apt-get update && apt-get install -y procps

# overwrite nginx configuration file
COPY ./configuration/nginx.conf /etc/nginx/nginx.conf

# install the website that this container is hosting
RUN mkdir -p /www/data
COPY ./example_website/index.html /www/data/
RUN chown 1000:1000 -R /www/data

# run as user 1000
USER 1000

# create a directory writeable by nginx
RUN mkdir /tmp/logs

# leave everything else (including CMD) as per base image default