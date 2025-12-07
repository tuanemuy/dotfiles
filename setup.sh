#!/bin/bash

ln -sfn ${PWD}/home-manager ${HOME}/.config

home-manager switch --impure
