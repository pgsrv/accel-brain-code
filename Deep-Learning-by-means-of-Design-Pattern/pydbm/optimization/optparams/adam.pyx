# -*- codiAdam utf-8 -*-
import numpy as np
cimport numpy as np
from pydbm.optimization.opt_params import OptParams


class Adam(OptParams):
    '''
    Adam.

    References:
        - Kingma, D. P., & Ba, J. (2014). Adam: A method for stochastic optimization. arXiv preprint arXiv:1412.6980.
    '''

    def __init__(self, double beta_1=0.9, double beta_2=0.99):
        '''
        Init.
        
        Args:
            beta_1:    A param.
            beta_2:    A param.
        '''
        self.__beta_1 = beta_1
        self.__beta_2 = beta_2
        self.__second_moment_list = []
        self.__first_moment_list = []
        self.__epoch = 0

    def optimize(self, params_list, grads_list, double learning_rate):
        '''
        Return of result from this optimization function.
        
        Override.

        Args:
            params_dict:    `list` of parameters.
            grads_list:     `list` of gradation.
            learning_rate:  Learning rate.

        Returns:
            `list` of optimized parameters.
        '''
        if len(params_list) != len(grads_list):
            raise ValueError("The row of `params_list` and `grads_list` must be equivalent.")

        if len(self.__first_moment_list) == 0 or len(self.__first_moment_list) != len(params_list):
            for i in range(len(params_list)):
                first_moment_arr = np.zeros_like(params_list[i])
                if first_moment_arr.ndim > 2:
                    first_moment_arr = first_moment_arr.reshape((
                        first_moment_arr.shape[0],
                        -1
                    ))
                self.__first_moment_list.append(first_moment_arr)

        if len(self.__second_moment_list) == 0 or len(self.__second_moment_list) != len(params_list):
            for i in range(len(params_list)):
                second_moment_arr = np.zeros_like(params_list[i])
                if second_moment_arr.ndim > 2:
                    second_moment_arr = second_moment_arr.reshape((
                        second_moment_arr.shape[0],
                        -1
                    ))
                self.__second_moment_list.append(second_moment_arr)
        
        if self.__first_moment_list[0] is None or self.__second_moment_list[0] is None:
            self.__epoch = 0

        self.__epoch += 1

        cdef double beta_2 = 1 - np.nanprod(
            np.array([self.__beta_2] * self.__epoch),
            axis=0
        )
        cdef double beta_1 = 1 - np.nanprod(
            np.array([self.__beta_1] * self.__epoch),
            axis=0
        )
        
        cdef double sqrt = np.sqrt(
            np.nanprod(
                np.array([beta_2, 1 / beta_1]),
                axis=0
            )
        )
        learning_rate = np.nanprod(np.array([learning_rate, sqrt]), axis=0)

        for i in range(len(params_list)):
            if params_list[i] is None or grads_list[i] is None:
                continue

            params_shape = params_list[i].shape
            params_ndim = params_list[i].ndim
            if params_ndim > 2:
                params_list[i] = params_list[i].reshape((
                    params_shape[0],
                    -1
                ))
            grads_shape = grads_list[i].shape
            grads_ndim = grads_list[i].ndim
            if grads_ndim > 2:
                grads_list[i] = grads_list[i].reshape((
                    grads_shape[0],
                    -1
                ))

            first_moment_arr = np.nansum(
                np.array([
                    np.expand_dims(grads_list[i], axis=0),
                    np.expand_dims(
                        np.nanprod(
                            np.array([
                                np.expand_dims(np.ones_like(self.__first_moment_list[i]) * -1, axis=0),
                                np.expand_dims(self.__first_moment_list[i], axis=0)
                            ]),
                            axis=0
                        )[0],
                        axis=0
                    )
                ]),
                axis=0
            )[0]
            try:
                first_moment_arr = (1 - self.__beta_1) * first_moment_arr
            except FloatingPointError:
                pass

            self.__first_moment_list[i] = np.nansum(
                np.array([
                    np.expand_dims(self.__first_moment_list[i], axis=0),
                    np.expand_dims(first_moment_arr, axis=0)
                ]),
                axis=0
            )[0]

            self.__second_moment_list[i] = np.nansum(
                np.array([
                    np.expand_dims(self.__second_moment_list[i], axis=0),
                    np.nanprod(
                        np.array([
                            np.expand_dims(np.ones_like(self.__second_moment_list[i]) * (1 - self.__beta_2), axis=0),
                            np.expand_dims(
                                np.nansum(
                                    np.array([
                                        np.nanprod(
                                            np.array([
                                                np.expand_dims(grads_list[i], axis=0),
                                                np.expand_dims(grads_list[i], axis=0)
                                            ]),
                                            axis=0
                                        ),
                                        np.expand_dims(-1 * self.__second_moment_list[i], axis=0)
                                    ]),
                                    axis=0
                                )[0],
                                axis=0
                            )
                        ]),
                        axis=0
                    )
                ]),
                axis=0
            )[0]

            var_arr = np.nanprod(
                np.array([
                    np.expand_dims(
                        np.nanprod(
                            np.array([
                                np.expand_dims(np.ones_like(self.__first_moment_list[i]) * learning_rate, axis=0),
                                np.expand_dims(self.__first_moment_list[i], axis=0)
                            ]),
                            axis=0
                        )[0],
                        axis=0
                    ),
                    np.expand_dims(1 / (np.sqrt(self.__second_moment_list[i]) + 0.00001), axis=0)
                ]),
                axis=0
            )[0]

            params_list[i] = np.nansum(
                np.array([
                    np.expand_dims(params_list[i], axis=0),
                    np.expand_dims(
                        np.nanprod(
                            np.array([
                                np.expand_dims(np.ones_like(var_arr) * -1, axis=0),
                                np.expand_dims(var_arr, axis=0)
                            ]),
                            axis=0
                        )[0],
                        axis=0
                    )
                ]),
                axis=0
            )[0]

            if params_ndim > 2:
                params_list[i] = params_list[i].reshape(params_shape)
            if grads_ndim > 2:
                grads_list[i] = grads_list[i].reshape(grads_shape)

        return params_list
