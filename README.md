socketClient
============

Example app written in Objective-C to communicate with a [Meteor Server](https://github.com/flashfabrixx/socketServer) using [ObjectiveDDP](https://github.com/boundsj/ObjectiveDDP) and Core Data to store and sync data for offline use.

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

Open the webapp at [http://localhost:3000](http://localhost:3000) and run the iOS app in the simulator. If you want to test the app on your device, make sure to update the server path in ``MeteorAgent.m`` with your hostname.

======================
#### Features

- Create, update and delete simple posts
- Webapp ([Server Repository](https://github.com/flashfabrixx/socketServer))
- [ObjectiveDDP](https://github.com/boundsj/ObjectiveDDP) to communicate with websocket
- Offline storage with Core Data and synchronisation

======================
#### Licensing  
MIT License.


