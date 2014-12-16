socketClient
============

Example app written in Objective-C to communicate with a [Meteor](https://www.meteor.com) Server using [ObjectiveDDP](https://github.com/boundsj/ObjectiveDDP) and store data using Core Data for offline access and data operations.

======================

#### Installation

````sh
# If not already installed, install Meteor first. 
curl https://install.meteor.com/ | sh

# Clone the server
git clone https://github.com/flashfabrixx/socketServer.git
cd socketServer
meteor

# Clone the app
git clone https://github.com/flashfabrixx/socketClient.git
cd socketClient
pod install
open socketClient.xcworkspace/
````
