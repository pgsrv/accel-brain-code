/*
Repository name: accel-brain-code
Description: Controller of auto completion.
Version: 1.0.1
Author: chimera0(RUM)
Author URI: http://accel-brain.com/
License: GNU General Public License v2.0
Copyright 2017 chimera0 (email : ai-brain-lab@accel-brain.com)
*/

var Controller = (function() {
    /*
     * @private
     *
     */
    autocompletion_ = null;

    /*
     * @private
     *
     */
    boltzmann_ = null;

    /*
     * @private
     *
     */
    q_learning_ = null;

    /*
     * @private
     *
     */
    input_memroy_ = "";

    /**
     * Set Up hyperparams.
     *
     * @params{object}
     *
     * @constructor
     */
    var constructor = function(params) {
        var nlp_base = new NlpBase();
        var n_gram = new Ngram();
        var autocompletion = new Autocompletion(
            nlp_base,
            n_gram,
            params.n
        );
        var boltzmann = new Boltzmann(
            autocompletion,
            {
                "time_rate": params.time_rate
            }
        );

        var q_learning = new QLearning(
            boltzmann,
            {
                "alpha_value": params.alpha_value,
                "gamma_value": params.gamma_value
            }
        );
        console.log("pre training is started.")
        autocompletion.pre_training(q_learning, params.document);

        limit_ = params.limit;

        this.autocompletion_ = autocompletion;
        this.boltzmann_ = boltzmann;
        this.q_learning_ = q_learning;
    }

    /** @constructor */
    constructor.prototype = {
        /**
         *
         * Tokenize document(string).
         *
         * @params {string}
         *
         * @return {string}
         *
         */
        recommend : function(input_document)
        {
            var state_key = this.autocompletion_.lap_extract_ngram(
                this.q_learning_,
                input_document
            );
            console.log("state:")
            console.log(state_key)
            this.q_learning_.learn(state_key, this.limit_);
            var next_action_list = this.q_learning_.extract_possible_actions(
                state_key
            );
            console.log("next action list:")
            console.log(next_action_list)
            var action_key = this.q_learning_.select_action(
                state_key,
                next_action_list
            );
            console.log("action:")
            console.log(action_key)
            var reward_value = this.q_learning_.observe_reward_value(
                state_key,
                action_key
            );
            console.log("reward_value:")
            console.log(reward_value)
            var q_value = this.q_learning_.extract_q_dict(
                state_key,
                action_key
            );
            console.log("q_value:")
            console.log(q_value)
            input_memroy_ = input_memroy_ + input_document;
            this.autocompletion_.pre_training(
                this.q_learning_,
                input_memroy_
            );
            return action_key;
        }
    }
    return constructor;

}) ();


