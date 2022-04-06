# Related List LWC Component for any SObject

This component allows you to place a Related Sobject List on any lightning record page and allows you to replace one or multiple related lists using filter conditions such as based on recordtype

![Related SObject List](https://github.com/vipultaylor/Related-SObject-List/blob/master/images/related-sobject-list.png)

## Features Summary

* Create a Related List component for any SObject on any "parent" Sobject satisfying different conditions previously not possible using standard related lists
* Combine multiple related lists (from multiple relationships on a single object) into one list
* Filter the records in the list based on Single or Multiple Recordtype(s)
* Filter the records in the list based on custom conditions
* Customize the New record behaviour
* Respects the security settings for the SObjects
* Mimic a View All behaviour similar to the standard related list

## Known Issues
* The related list does not refresh when a new record is created. A separate refresh button is added allowing users to manually refresh the list
* The related list does not refresh when a record from the list is edited. A separate refresh button is added allowing users to manually refresh the list
* Every ime you click the View All button (in a console app), it opens up a new subtab

## Documentation

The documentation on how to set up and use this component is available [here](https://github.com/vipultaylor/Related-SObject-List/wiki)
