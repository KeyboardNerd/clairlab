Based on the newapi design

For the scanning part,
If we version EVERY single thing, and we assume that EVERY single entities are inserted and never updated or deleted in the database.
Clair's performance will be so much improved!

The database will be something like:
```
Entity
ID, Name, Version, Type ( REF to Type )

Entity Relation
ID, Root Entity, Parent Entity, Current Entity # all entities are namespaced by Root Entity

Type ( ENUM )
ID, Name

Affected Entity
ID, Entity Relation ID ( affect on current entity ), Vulnerability Entity Relation ID

Severity ( ENUM )
ID, Name

Vulnerability ( metadata for vulnerabilities )
ID, Name, Link, Metadata, Changed, Severity

Vulnerability Entity Relation ( anything under the parent entity are subject to be affected )
ID, Vulnerability ID, Parent Entity, Name, Type, VersionRange

Notification ( when a vulnerability is changed, a notification is created )
ID, UUID, new vulnerability, old vulnerability

Notification Root Entity Change Log ( computed when a vulnerability is changed )
ID, Notification, Root Entity, Status ( Add or Remove )

Notification Status ( ENUM )
ID, Name ( ADD, REMOVED )
```
