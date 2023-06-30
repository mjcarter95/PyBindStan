# PyBindStan
PyBindStan is a Python interface to Stan. This package is a boiled down version of [HTTPStan](https://github.com/stan-dev/httpstan) with no REST API.

### Requirements
System requirements: Mac or Ubuntu

- Python3-devtools
- curl

### Installation

```
git clone https://github.com/mjcarter95/PyBindStan.git
cd PyBindStan

make

python3 -m pip install requirements.txt
python3 -m pip install -e .
```

Note, for `make` to run, you must install `curl`, `python3-devtools` and `build-essential`

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

### Contributions and Citations
Please follow the Citation and Contribution guidelines outlined in the HTTPStan repository.
