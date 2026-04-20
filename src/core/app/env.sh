#!/usr/bin/env bash

# c1


echo "start"



(
    # c2
    echo "pipe-sub"


    # c3
    missing_runtime_cmd_10     # target inline comment

    # c4
) | cat


echo "end"