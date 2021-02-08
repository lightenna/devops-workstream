# based on Node on account of NPM installs
FROM node:lts
ARG SERVICENAME=microservice

# install minimal packages to enable run and test
RUN apt-get -qq update && apt-get -qq -y install curl net-tools

# create app directory
WORKDIR "/usr/src/$SERVICENAME"

# copy package.json for JS deps
COPY package.json .
COPY package-lock.json .

# install using NPM
RUN npm install

# copy app source code to image filesystem
COPY . .

# give node user read-only access to executable and deps
RUN chown root:node -R ./ && chmod 0750 -R ./

# run as node user
USER node

# tell the service to run on named port by default
ENV PORT=3031

# run the specified command within the container.
CMD [ "npm", "start" ]

