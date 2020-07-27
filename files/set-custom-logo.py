# https://github.com/ansible/awx/issues/4492

import base64
import os

from awxkit import api, config
from awxkit.utils import PseudoNamespace as ns

# set config
config.credentials = ns({'default': {'username': os.environ.get('AWX_ADMIN_USER'),
                                     'password': os.environ.get('AWX_ADMIN_PASSWORD')}})
config.base_url = 'http://awx-web:8052'

# load logofile
logofile = open("/home/awx/logo-osism.png", "rb")
logo_64_encode = base64.b64encode(logofile.read()).decode()
created_data_url = 'data:image/png;base64,{}'.format(logo_64_encode)

# update logo in api
root = api.Api()
root.load_session().get()
v2 = root.available_versions.v2.get()
settings_all = v2.settings.get().get_endpoint('all')
settings_all.CUSTOM_LOGO = created_data_url  # implicitly makes a patch request
