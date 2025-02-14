# Use the official Node.js 14 image as a parent image
FROM node:14

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy package.json and package-lock.json (if available)
COPY package*.json ./

# Install project dependencies
RUN npm install

# Copy the project files into the container
COPY . .

# Make port 3001 available to the world outside this container
EXPOSE 3001

# Run the server when the container starts
CMD [ "npm", "start" ]
