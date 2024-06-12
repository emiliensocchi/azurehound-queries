# Miscellaneous interactive queries

Collection of extra BloodHound queries for Azure requiring manual user input.


## Find all resources using the passed MI

```shell
MATCH p = (n)-[:AZManagedIdentity]-(n2 WHERE n2.displayname = '__REPLACE__') RETURN p
```
