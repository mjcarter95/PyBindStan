# PyBindStan
PyBindStan is a Python interface to Stan. This package is a boiled down version of [HTTPStan](https://github.com/stan-dev/httpstan) with no REST API.

### Requirements
System requirements: Mac or Ubuntu (will extend to Windows soon)


### Installation

```
git init
git remote add origin git@github.com:mjcarter95/PyBindStan.git
git pull origin main

python3 -m venv venv
source activate venv/bin/activate

cd pybindstan
make

python3 -m pip install requirements.txt
python3 -m pip install -e pybindstan
```

### Example
```
from pybindstan.model import Model

from time import time

stan_code = """
parameters {
    real y;
    real x;
}
model {
    y ~ normal(0,1);
    x ~ normal(0, 1);
}
generated quantities {
    real z = x + y;
}
"""

data = {}

# Instantiate model object
model_name = "stan_model"
model = Model(model_name=model_name, program_code=stan_code, data={})

# Compile model
model.compile()

# Calculate log probability of y
y = [1, 2]
model.log_prob(y)
```