# DEPRICATED

Facebook Parse shut down 1/30/2017. Though you can run the parse code on your cloud-of-choice, we decided Parse wasn't the way to go. Some probolems with Parse:

* The main problem is it actually doesn't scale like the claimed. Parse uses MongoDB and MongoDB doesn't scale transparently from 1 machine to hundreds or more.
* Poor developer experience developing and debugging "cloud-code"
* Course access-control-list (per-record, but not per-field). This seems like a little thing until you realize -every- application has user records and -every- user record is part public and part private. It's really awkward to solve this problem on Parse.

# ArtEry

An so, we invented ArtEry, a backend and hosting agnostic zero-server-code framework. We are currently using Heroku for hosting and DynamoDb for the backend.

Learn more:

* [ArtEry](https://github.com/imikimi/art-ery)
* [ArtEryAws](https://github.com/imikimi/art-ery-aws)