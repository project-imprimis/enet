#!/bin/sh
# ENet cflags detection for unix by Daniel 'q66' Kolesa <quaker66@gmail.com>
# I hereby put this file into public domain, use as you wish

CC = $*
#need to create temp files to use in checking below, note that there will be inline
#macro overloads of the text in these files

#creates a simple file to check if a function exists
cat << EOF > check_func.c
void TEST_FUN();
int main() { TEST_FUN(); return 0; }
EOF

#creates a simple file to check if TEST_FIELD is in TEST_STRUCT
cat << EOF > check_member.c
#include "check_member.h"
static void pass() {}
int main() { struct TEST_STRUCT test; pass(test.TEST_FIELD); return 0; }
EOF

#creates a simple file to check if a var can be assigned to TEST_TYPE
cat << EOF > check_type.c
#include "check_type.h"
int main() { TEST_TYPE test; return 0; }
EOF

#allows for the checking of whether a function is validly present
# CC : the C compiler
# check_func.c : use the check_func file above
# -DTEST_FUN=$1 :
# -o check_func : write output to check_func (gets deleted immediately)
# 2>/dev/null : write stderr to dev/null

CHECK_FUNC() {
    $CC check_func.c -DTEST_FUN=$1 -o check_func 2>/dev/null
    if [ $? -eq 0 ]; then printf " $2"; rm check_func; fi
}

CHECK_FUNC getaddrinfo -DHAS_GETADDRINFO
CHECK_FUNC getnameinfo -DHAS_GETNAMEINFO
CHECK_FUNC gethostbyaddr_r -DHAS_GETHOSTBYADDR_R
CHECK_FUNC gethostbyname_r -DHAS_GETHOSTBYNAME_R
CHECK_FUNC poll -DHAS_POLL
CHECK_FUNC fcntl -DHAS_FCNTL
CHECK_FUNC inet_pton -DHAS_INET_PTON
CHECK_FUNC inet_ntop -DHAS_INET_NTOP

#create a header that includes sys/socket.h
echo "#include <sys/socket.h>" > check_member.h

$CC check_member.c -DTEST_STRUCT=msghdr -DTEST_FIELD=msg_flags \
    -o check_member 2>/dev/null
if [ $? -eq 0 ]; then printf " -DHAS_MSGHDR_FLAGS"; rm check_member; fi
rm check_member.h

#create a header that includes sys/types.h and sys/socket.h
echo "#include <sys/types.h>" > check_type.h
echo "#include <sys/socket.h>" >> check_type.h
$CC check_type.c -DTEST_TYPE=socklen_t -o check_type 2>/dev/null
if [ $? -eq 0 ]; then printf " -DHAS_SOCKLEN_T"; rm check_type; fi
rm check_type.h

#delete temp c files
echo ''
rm check_func.c
rm check_member.c
rm check_type.c
