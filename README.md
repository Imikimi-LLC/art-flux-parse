# DEPRICATED

Facebook Parse shut down 1/30/2017. Though you can run the parse code on your cloud-of-choice, we decided Parse wasn't the way to go. Some probolems with Parse:

* Parse doesn't scale infinitly like they claimed. Parse uses MongoDB and MongoDB doesn't scale transparently from 1 machine to hundreds or more.
* Poor developer experience developing and debugging "cloud-code"
* Too-Course and Too-Fine access control.
  * You can't set per-table policies. Everything is done on a per-record bases. Change your policy, and you have to update every record in the entire table. This is impossible with any real amount of data.
  * You can't control per-field access. This seems like a little thing until you realize *every* application has user records and *every* user record has a public part and a private part. It's really awkward to solve this problem with Parse.

# ArtEry

And so, we invented ArtEry, a hosting, database, security-policy agnostic "100% Client-Side Cloud-Code Development" framework.

Learn more:

* [ArtEry](https://github.com/imikimi/art-ery)
* [ArtEryAws](https://github.com/imikimi/art-ery-aws)