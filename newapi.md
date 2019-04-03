What if we define a recursive structure to hold all the information?
```
{
  "name": "sha256:1239408192391023920",
  "type": "manifest",
  "version": "scanned_by_clair-v3.1",
  "vulnerabilities": [],
  "children": [
    {
      "name": "sha256:120389abc20319103f2",
      "version": "scanned_by_clair-v3.1",
      "type": "layer",
      "vulnerabilities": [],
      "children": [
        {
          "name": "RHEL",
          "version": "7.0",
          "type": "os",
          "vulnerabilities": [],
          "children": [
            {
            	"name": "openssl",
            	"version": "1.1.1b-1",
            	"type": "srpm",
                "vulnerabilities": [
                  "CVE-110"
                ],
                "children": [
                	{
                		"name": "libssl-dev",
                		"version": "1.1.1b-1",
                		"type": "rpm",
                		"vulnerabilities": []
                	},
                	{
                		"name": "libcrypto1.1-udeb",
                		"version": "1.1.1b-1",
                		"type": "rpm",
                		"vulnerabilities": []
                	}
                ]
            },
            {
            	"name": "python",
            	"version": "2.7.15",
            	"type": "rpm",
            	"vulnerabilities": [],
            	"children": [
            		{
            			"name": "flask",
            			"version": "1.0.2",
            			"type": "python",
            			"vulnerabilities": []
            		}
            	]
            }
          ]
        },
      ]
    }
  ]
}
```
