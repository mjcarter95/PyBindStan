import numpy as np

import pybindstan.cache
import pybindstan.models


class Model:
    def __init__(self, model_name, program_code, data):
        self.program_code = program_code
        self.data = data
        self.D = 0
        self.model_name = f"model/{model_name}"
    
    def compile(self):
        print(f"Compiling {self.model_name}, this can take a long time...")

        # check if extension module is present in cache
        try:
            pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            pass
        else:
            compiler_output = pybindstan.cache.load_services_extension_module_compiler_output(self.model_name)
            # stanc_warnings = pybindstan.cache.load_stanc_warnings(model_name)
            self.D = self.n_pars()
            return compiler_output

        pybindstan.cache.delete_model_directory(self.model_name)

        try:
            # `build_services_extension_module` has side-effect of storing extension module in cache
            compiler_output = pybindstan.models.build_services_extension_module(self.model_name, self.program_code)
        
        except Exception as exc:  # pragma: no cover
            return exc
        pybindstan.cache.dump_services_extension_module_compiler_output(compiler_output, self.model_name)

        self.D = self.n_pars()

        print(f"Finished compiling model {self.model_name}")

        return compiler_output

    def n_pars(self):
        try:
            services_module = pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            print(f"Error model {self.model_name} not found")
            return None
        try:
            n_pars = services_module.n_pars(self.data) # type: ignore
            return n_pars
        except Exception as e:
            print(f"Error whilst determining n_pars for {self.model_name}\n{e}")
            return None

    def get_param_names(self):
        try:
            services_module = pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            print(f"Error model {self.model_name} not found")
            return None
        try:
            param_names = services_module.get_param_names(self.data) # type: ignore
            return param_names
        except Exception as e:
            print(f"Error whilst extracting param_names for {self.model_name}\n{e}")
            return None
            
    def constrained_param_names(self):
        try:
            services_module = pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            print(f"Error model {self.model_name} not found")
            return None
        try:
            param_names = services_module.constrained_param_names(self.data) # type: ignore
            return param_names
        except Exception as e:
            print(f"Error whilst extracting param_names for {self.model_name}\n{e}")
            return None

    def unconstrained_param_names(self):
        try:
            services_module = pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            print(f"Error model {self.model_name} not found")
            return None
        try:
            param_names = services_module.constrained_param_names(self.data) # type: ignore
            return param_names
        except Exception as e:
            print(f"Error whilst extracting param_names for {self.model_name}\n{e}")
            return None

    def constrain_pars(self, upar, include_tparams=True, include_gqs=True):
        try:
            services_module = pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            print(f"Error model {self.model_name} not found")
            return None
        try:
            cpar = services_module.write_array(self.data, upar, include_tparams, include_gqs) # type: ignore
            return cpar
        except Exception as e:
            print(f"Error whilst calculating constrained parameters for {self.model_name}\n{e}")
            return np.inf
    
    def unconstrain_pars(self, cpar):
        try:
            services_module = pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            print(f"Error model {self.model_name} not found")
            return None
        try:
            upar = services_module.log_prob(self.data, cpar) # type: ignore
            return upar
        except Exception as e:
            print(f"Error whilst calculating unconstraiend parameters for {self.model_name}\n{e}")
            return np.inf
    
    def log_prob(self, upar, adjust_transform=True):
        try:
            services_module = pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            print(f"Error model {self.model_name} not found")
            return None
        try:
            lp = services_module.log_prob(self.data, upar, adjust_transform) # type: ignore
            return lp
        except Exception as e:
            print(f"Error whilst calculating log_prob for {self.model_name}\n{e}")
            return np.inf

    def log_prob_grad(self, upar, adjust_transform=True):
        try:
            services_module = pybindstan.models.import_services_extension_module(self.model_name)
        except KeyError:
            print(f"Error model {self.model_name} not found")
            return None
        try:
            lp = services_module.log_prob_grad(self.data, upar, adjust_transform) # type: ignore
            return lp
        except Exception as e:
            print(f"Error whilst calculating log_prob for {self.model_name}\n{e}")
            return np.inf

