#!/bin/bash

RBENV_ROOT=/usr/local/rbenv

git clone https://github.com/sstephenson/rbenv.git ${RBENV_ROOT}
git clone https://github.com/sstephenson/ruby-build.git ${RBENV_ROOT}/plugins/ruby-build

echo "export RBENV_ROOT=${RBENV_ROOT}" >> /etc/profile.d/rbenv.sh
echo 'export PATH="${RBENV_ROOT}/bin:$PATH"' >> /etc/profile.d/rbenv.sh
echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh
source /etc/profile.d/rbenv.sh
rbenv --version

${RBENV_ROOT}/plugins/ruby-build/install.sh
