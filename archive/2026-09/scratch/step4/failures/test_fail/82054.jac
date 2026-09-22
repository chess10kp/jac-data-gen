"""Checks if port is open on host"""
def is_port_free(port: Any, host: Any = "localhost") -> object {
    import socket;
    import from contextlib { closing }
    with closing(socket.socket(socket.AF_INET, socket.SOCK_STREAM)) as sock {
        if (sock.connect_ex((host, port)) == 0) {
            return False;
        } else {
            return True;
        }
    }
}

test "t0" {
    assert (is_port_free(8103) == True);;
}

test "t1" {
    assert (is_port_free(55555) == True);;
}

test "t2" {
    assert (is_port_free(8092) == True);;
}

test "t3" {
    assert (is_port_free(8093) == True);;
}

test "t4" {
    assert (is_port_free(8890) == True);;
}

test "t5" {
    assert (is_port_free(8080) == True);;
}

test "t6" {
    assert (is_port_free(3000, "127.0.0.1") == True);;
}

test "t7" {
    assert (is_port_free(2000) == True);;
}

test "t8" {
    assert (is_port_free(80) == True);;
}

test "t9" {
    assert (is_port_free(8888) == True);;
}

test "t10" {
    assert (is_port_free(23, "localhost") == True);;
}

test "t11" {
    assert (is_port_free(8097) == True);;
}

test "t12" {
    assert (is_port_free(8000, "localhost") == False);;
}

test "t13" {
    assert (is_port_free(1234) == True);;
}

test "t14" {
    assert (is_port_free(8083) == True);;
}

test "t15" {
    assert (is_port_free(8094) == True);;
}

test "t16" {
    assert (is_port_free(65535, "localhost") == True);;
}

test "t17" {
    assert (is_port_free(8080, "localhost") == True);;
}

test "t18" {
    assert (is_port_free(1234, "localhost") == True);;
}

test "t19" {
    assert (is_port_free(999) == True);;
}

test "t20" {
    assert (is_port_free(777) == True);;
}

test "t21" {
    assert (is_port_free(1337) == True);;
}

test "t22" {
    assert (is_port_free(27017) == True);;
}

test "t23" {
    assert (is_port_free(8095) == True);;
}

test "t24" {
    assert (is_port_free(1337, "localhost") == True);;
}

test "t25" {
    assert (is_port_free(1) == True);;
}

test "t26" {
    assert (is_port_free(8099) == True);;
}

test "t27" {
    assert (is_port_free(8084) == True);;
}

test "t28" {
    assert (is_port_free(8102) == True);;
}

test "t29" {
    assert (is_port_free(1337, "127.0.0.2") == True);;
}

test "t30" {
    assert (is_port_free(8087) == True);;
}

test "t31" {
    assert (is_port_free(22) == True);;
}

test "t32" {
    assert (is_port_free(8088) == True);;
}

test "t33" {
    assert (is_port_free(5000, "127.0.0.1") == True);;
}

test "t34" {
    assert (is_port_free(8090) == True);;
}

test "t35" {
    assert (is_port_free(8100) == True);;
}

test "t36" {
    assert (is_port_free(4040, "localhost") == True);;
}

test "t37" {
    assert (is_port_free(12345, "localhost") == True);;
}

test "t38" {
    assert (is_port_free(22, "localhost") == True);;
}

test "t39" {
    assert (is_port_free(30000) == True);;
}

test "t40" {
    assert (is_port_free(8089) == True);;
}

test "t41" {
    assert (is_port_free(5000) == True);;
}

test "t42" {
    assert (is_port_free(1000) == True);;
}

test "t43" {
    assert (is_port_free(443) == True);;
}

test "t44" {
    assert (is_port_free(12345) == True);;
}

test "t45" {
    assert (is_port_free(8081) == True);;
}

test "t46" {
    assert (is_port_free(8096) == True);;
}

test "t47" {
    assert (is_port_free(1337, "127.0.0.1") == True);;
}

test "t48" {
    assert (is_port_free(80, "localhost") == True);;
}

test "t49" {
    assert (is_port_free(8085) == True);;
}

test "t50" {
    assert (is_port_free(5000, "localhost") == True);;
}

test "t51" {
    assert (is_port_free(1234, "127.0.0.1") == True);;
}

test "t52" {
    assert (is_port_free(8000) == False);;
}

test "t53" {
    assert (is_port_free(8098) == True);;
}

test "t54" {
    assert (is_port_free(8086) == True);;
}

test "t55" {
    assert (is_port_free(4040) == True);;
}

test "t56" {
    assert (is_port_free(1, "localhost") == True);;
}

test "t57" {
    assert (is_port_free(8091) == True);;
}

test "t58" {
    assert (is_port_free(8101) == True);;
}

test "t59" {
    assert (is_port_free(23) == True);;
}

test "t60" {
    assert (is_port_free(44444) == True);;
}

test "t61" {
    assert (is_port_free(1337, "0.0.0.0") == True);;
}

test "t62" {
    assert (is_port_free(65535) == True);;
}

test "t63" {
    assert (is_port_free(888) == True);;
}

test "t64" {
    assert (is_port_free(8082) == True);;
}
