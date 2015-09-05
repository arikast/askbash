release notes for version 0.6.3 
- changed the signature of the abbreviate method to include the raw data from the node, and refactored only known invocations accordingly
- deprecated FilesCSVCompleter since now FilesCompleter can do the same thing by specifying a separator like this "<Files>,"
- refactored jekyll.yaml to use the new FilesCompleter

This project intends to adhere to semantic versioning after 1.0.0, but not prior to this.  Therefore while this release technically breaks a minor API, the version will still remain at 0.*
