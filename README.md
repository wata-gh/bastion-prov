# bastion-prov

# Install

```shell
git clone https://github.com/wata-gh/survey-prov.git
cd survey-prov
bundle --path vendor/bundle
```

## Configure

### make webservice password

make password wich SHA512.
```
$ gem install unix-crypt
$ mkunixcrypt -s "salt"
Enter password:
Verify password:
$6$salt$...
```

#### nodes/bastion.json
```json
{
  "base": {
    "users": {
      "webservice": {
        "create-home": "",
        "password": "[webservice password]"
      }
    }
  },
  "rtn_rbenv": {
    "user": "webservice",
    "versions": {
      "2.2.3": ["bundler"]
    },
    "global": "2.2.3"
  },
  "cert": {
    "common_name": "[bastion host name]"
  },
  "bastion": {
    "app": {
      "name": "[name of your application]"
    },
    "aws_config": {
      "access_key_id": "[aws access_key_id]",
      "secret_access_key": "[aws secret_access_key]",
      "region": "[aws region]"
    },
    "security_group": {
      "bastion": {
        "group_id": "[bastion security group id]",
        "defaults": "[default IPs]"
      },
      "webservice": {
        "group_id": "[webservice security group id]",
        "defaults": "[default IPs]"
      }
    }
  }
}
```

## Provisioning

```shell
bundle exec itamae ssh -u ec2-user -h [ec2 instance host] -j nodes/bastion.json roles/bastion.rb
```
