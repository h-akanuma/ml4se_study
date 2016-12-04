#!/bin/bash

PYENV_ROOT=/usr/local/pyenv

git clone https://github.com/yyuu/pyenv.git ${PYENV_ROOT}

echo "export PYENV_ROOT=${PYENV_ROOT}" >> /etc/profile.d/pyenv.sh
echo 'export PATH="${PYENV_ROOT}/bin:$PATH"' >> /etc/profile.d/pyenv.sh
echo 'eval "$(pyenv init -)"' >> /etc/profile.d/pyenv.sh
source /etc/profile.d/pyenv.sh
