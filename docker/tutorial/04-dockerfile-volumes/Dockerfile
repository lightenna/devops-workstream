# build from base image
FROM nginx:latest
RUN apt-get update && apt-get install -y procps

# create base folder path for hosting website
RUN mkdir -p /www
RUN chown 1000:1000 -R /www

# run as user 1000
USER 1000

# create a directory writeable by nginx
RUN mkdir /tmp/logs

# leave everything else (including CMD) as per base image default