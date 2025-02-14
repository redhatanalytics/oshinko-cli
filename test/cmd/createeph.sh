#!/bin/bash
source "$(dirname "${BASH_SOURCE}")/../../hack/lib/init.sh"
trap os::test::junit::reconcile_output EXIT

os::test::junit::declare_suite_start "cmd/createeph"

# No clusters notice
os::cmd::try_until_text "_output/oshinko get" "No clusters found."

# name required
os::cmd::expect_failure "_output/oshinko create_eph"

# default one worker / one master
os::cmd::expect_success "_output/oshinko create_eph abc"
os::cmd::expect_success "_output/oshinko get abc -o yaml | grep 'WorkersCount: 1'"
os::cmd::expect_success "_output/oshinko get abc -o yaml | grep 'MastersCount: 1'"
os::cmd::expect_success "_output/oshinko delete abc"

# workers flag
os::cmd::expect_success "_output/oshinko create_eph def --workers=-1"
os::cmd::expect_success "_output/oshinko get def -o yaml | grep 'WorkersCount: 1'"
os::cmd::expect_success "_output/oshinko delete def"

os::cmd::expect_success "_output/oshinko create_eph ghi --workers=2"
os::cmd::expect_success "_output/oshinko get ghi -o yaml | grep 'WorkersCount: 2'"
os::cmd::expect_success "_output/oshinko delete ghi"

os::cmd::expect_success "_output/oshinko create_eph sam --workers=0"
os::cmd::expect_success "_output/oshinko get sam -o yaml | grep 'WorkersCount: 0'"
os::cmd::expect_success "_output/oshinko delete sam"

# masters flag
os::cmd::expect_success "_output/oshinko create_eph jkl --masters=-1"
os::cmd::expect_success "_output/oshinko get jkl -o yaml | grep 'MastersCount: 1'"
os::cmd::expect_success "_output/oshinko delete jkl"

os::cmd::expect_success "_output/oshinko create_eph jill --masters=0"
os::cmd::expect_success "_output/oshinko get jill -o yaml | grep 'MastersCount: 0'"
os::cmd::expect_success "_output/oshinko delete jill"

os::cmd::expect_failure_and_text "_output/oshinko create_eph mno --masters=2" "cluster configuration must have a master count of 0 or 1"

# workerconfig
os::cmd::expect_success "oc create configmap testmap"
os::cmd::expect_failure_and_text "_output/oshinko create_eph mno --workerconfig=jack" "unable to find spark configuration 'jack'"
os::cmd::expect_success "_output/oshinko create_eph mno --workerconfig=testmap"
os::cmd::expect_success "_output/oshinko delete mno"

# masterconfig
os::cmd::expect_failure_and_text "_output/oshinko create_eph mno --masterconfig=jack" "unable to find spark configuration 'jack'"
os::cmd::expect_success "_output/oshinko create_eph pqr --masterconfig=testmap"
os::cmd::expect_success "_output/oshinko delete pqr"

# create against existing cluster
os::cmd::expect_success "_output/oshinko create_eph sally"
os::cmd::expect_failure_and_text "_output/oshinko create_eph sally" "cluster 'sally' already exists"

# create against incomplete clusters
os::cmd::expect_success "oc delete service sally-ui"
os::cmd::expect_failure_and_text "_output/oshinko create_eph sally" "cluster 'sally' already exists \(incomplete\)"

# exposeui
os::cmd::expect_success "_output/oshinko create_eph charlie --exposeui=false"
os::cmd::expect_success_and_text "_output/oshinko get -d charlie" "charlie.*<no route>"

# storedconfig
oc create configmap clusterconfig --from-literal=workercount=3 --from-literal=mastercount=0 
os::cmd::expect_failure_and_text "_output/oshinko create_eph chicken --storedconfig=jack" "named config 'jack' does not exist"
os::cmd::expect_success "_output/oshinko create_eph chicken --storedconfig=clusterconfig"
os::cmd::expect_success_and_text "_output/oshinko get chicken -o yaml" "WorkersCount: 3"
os::cmd::expect_success_and_text "_output/oshinko get chicken -o yaml" "MastersCount: 0"

os::cmd::expect_success "_output/oshinko create_eph hawk --workers=1 --masters=1 --storedconfig=clusterconfig"
os::cmd::expect_success_and_text "_output/oshinko get hawk -o yaml" "WorkersCount: 1"
os::cmd::expect_success_and_text "_output/oshinko get hawk -o yaml" "MastersCount: 1"

# image
os::cmd::expect_success "_output/oshinko create_eph cordial --image=someotherimage"

# flags for ephemeral
os::cmd::expect_failure_and_text "_output/oshinko create_eph -e bob" "An app value must be supplied if ephemeral is used"

os::cmd::expect_success_and_text "_output/oshinko create_eph -e bob --app=kingkong" 'shared cluster bob'

os::cmd::expect_success_and_text "_output/oshinko create_eph -e sonofbob --app=bob-m-1" 'ephemeral cluster sonofbob'
os::cmd::expect_success_and_text "oc export rc bob-m-1" "uses-oshinko-cluster: sonofbob"

os::cmd::expect_success_and_text "_output/oshinko create_eph vinny --app=sonofbob-m-1" 'shared cluster vinny'
os::cmd::expect_success_and_text "oc export rc sonofbob-m-1" "uses-oshinko-cluster: vinny"

os::test::junit::declare_suite_end
