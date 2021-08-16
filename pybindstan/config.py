import os

PYBINDSTAN_DEBUG = os.environ.get("PYBINDSTAN_DEBUG", "0") in {"true", "1"}
