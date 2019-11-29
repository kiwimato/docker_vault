#!/usr/bin/python3

import hvac
import json
import yaml


# Checks if there's a multi line value and converts it to a block literal
def str_presenter(dumper, data):
    if len(data.splitlines()) > 1:  # check for multiline string
        return dumper.represent_scalar('tag:yaml.org,2002:str', data, style='|')
    return dumper.represent_scalar('tag:yaml.org,2002:str', data)


token = 's.c4Pixeo7HkXSFbSeGmIggHXR'
client = hvac.Client(url='https://127.0.0.1:8200', token=token)
print(f"[*] Authenticate response: {client.is_authenticated()}")

# KV Value - useful for storing entire JSON files, etc
kv_bla = client.secrets.kv.read_secret_version(path='production', version=1, mount_point='service-supply')
print(f"[*] Got Key Value data for service-supply/production: {json.dumps(kv_bla, indent=4, sort_keys=True)}")

yaml.add_representer(str, str_presenter)
yaml_data = yaml.dump(yaml.safe_load(json.dumps(kv_bla['data'])))
print("\n[*] JSON above converted to YAML format:{}".format(yaml_data))

# Normal secret
top_secret = client.read(path="cubbyhole/top")
print(f"Got value for cubbyhole/top: {json.dumps(top_secret, indent=4, sort_keys=True)}")

client.logout()
