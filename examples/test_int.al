import test
import int

// effect: tests that actual and expected are equal. If not then the message
//      will be printed.
proc assert_int_eq actual:Int expected:Int name:Tape {
    let r = ""
    int_eq actual expected r
    assert_tape actual.bin expected.bin r name
}

// Tests setting the value of an integer.
proc test_set {
    let num = Int "001"
    set num (Int "101")
    assert_int_eq num (Int "101") "Setting int"
}
test_set

// Tests checking whether an integer is zero.
proc test_is_zero {
    proc assert_is_zero num:Int exp:Tape name:Tape {
        let out = ""
        is_zero num out
        assert_tape_eq out exp name
    }

    assert_is_zero (Int "0") "1" "is_zero 0"
    assert_is_zero (Int "1") "0" "is_zero 1"
    assert_is_zero (Int "000") "1" "is_zero 000"
    assert_is_zero (Int "00000100") "0" "is_zero 00000100"
}
test_is_zero

// Tests checking whether two numbers are equal, ignoring leading zeros.
proc test_int_eq {
    proc assert_is_eq x:Int y:Int exp:Tape name:Tape {
        let out = ""
        int_eq x y out
        assert_tape_eq out exp name
    }

    // Tests equality when there are the same number of bits in each operand.
    proc test_same_num_bits {
        assert_is_eq (Int "0") (Int "0") "1" "0==0"
        assert_is_eq (Int "1") (Int "1") "1" "1==1"
        assert_is_eq (Int "0") (Int "1") "0" "0==1"
        assert_is_eq (Int "101101") (Int "101101") "1" "101101==101101"
        assert_is_eq (Int "1011010") (Int "1011011") "0" "1011010==1011011"
    }
    test_same_num_bits

    // Tests equality when there are different number of bits in each operand.
    proc test_diff_num_bits {
        assert_is_eq (Int "00") (Int "0") "1" "00==0"
        assert_is_eq (Int "10") (Int "1") "1" "10==1"
        assert_is_eq (Int "10000") (Int "1") "1" "10000==1"
        assert_is_eq (Int "100001") (Int "1") "0" "100001==1"
        assert_is_eq (Int "011") (Int "0110000") "1" "011==0110000"
        assert_is_eq (Int "011") (Int "011000010") "0" "011==011000010"
    }
    test_diff_num_bits
}
test_int_eq

// Tests addition of binary integers.
proc test_add {
    proc assert_add x:Int y:Int exp:Int name:Tape {
        let out = Int ""
        add x y out
        assert_int_eq out exp name
    }

    // Tests basic adding of integers with same number of bits.
    proc test_same_num_bits {
        assert_add (Int "0") (Int "0") (Int "00") "0+0"
        assert_add (Int "1") (Int "0") (Int "10") "1+0"
        assert_add (Int "1011") (Int "0110") (Int "11001") "1101+110"
        assert_add (Int "101101011") (Int "010101110") (Int "1110100101") "110101101+011101010"
    }
    test_same_num_bits

    // Tests using the same integer as both operands.
    proc test_same_operand {
        let x = Int "01"
        assert_add x x (Int "001") "Adding same integer as both operands"
    }
    test_same_operand

    // Tests writing to one of the input operands.
    proc test_same_out {
        let x = Int "01"
        add x (Int "10") x
        assert_int_eq x (Int "11") "Using integer as input and output"
    }
    test_same_out

    // Tests adding when both inputs and the output are the same integer.
    proc test_all_same_operands {
        let x = Int "10"
        add x x x
        assert_int_eq x (Int "01") "Using integer as all inputs and output"
    }
    test_all_same_operands

    // Tests performing one addition followed by another.
    proc test_multiple_adds {
        let x = Int "10"
        let y = Int "10"

        let r1 = Int ""
        let r2 = Int ""

        add x y r1
        add r1 y r2

        assert_int_eq r2 (Int "11") "Chaining additions"
    }
    test_multiple_adds
}
test_add

// Tests the binary subtraction of integers.
proc test_sub {
    proc assert_sub x:Int y:Int exp:Int name:Tape {
        let out = Int ""
        sub x y out
        assert_int_eq out exp name
    }

    // Tests basic subtraction of integers with the same number of bits.
    proc test_same_num_bits {
        assert_sub (Int "0") (Int "0") (Int "00") "0-0"
        assert_sub (Int "1") (Int "0") (Int "10") "1-0"
        assert_sub (Int "1011") (Int "0110") (Int "11100") "1101-110"
        assert_sub (Int "101101011") (Int "010101110") (Int "1100001100") "110101101-011101010"
    }
    test_same_num_bits

    // Tests using the same integer as both operands.
    proc test_same_operand {
        let x = Int ("01")
        assert_sub x x (Int "0") "Subtracting same integer as both operands"
    }
    test_same_operand

    // Tests writing to one of the input operands.
    proc test_same_out {
        let x = Int "11"
        sub x (Int "10") x
        assert_int_eq x (Int "01") "Using integer as input and output"
    }
    test_same_out

    // Tests subtracting when both inputs and the output are the same integer.
    proc test_all_same_operands {
        let x = Int "10"
        sub x x x
        assert_int_eq x (Int "0") "Using integer as all inputs and output"
    }
    test_all_same_operands

    // Tests performing one subtraction followed by another.
    proc test_multiple_subs {
        let x = Int "11"
        let y = Int "10"

        let r1 = Int ""
        let r2 = Int ""

        sub x y r1
        sub r1 y r2

        assert_int_eq r2 (Int "1") "Chaining subtractions"
    }
    test_multiple_subs
}
test_sub

// Tests the increment function, i.e. which performs x+=dx
proc test_inc {
    proc assert_inc x:Int dx:Int exp:Int name:Tape {
        inc x dx
        assert_int_eq x exp name
    }

    assert_inc (Int "0") (Int "1") (Int "1") "0+=1"
    assert_inc (Int "1") (Int "1") (Int "01") "1+=1"
    assert_inc (Int "1011") (Int "0110") (Int "11001") "1+=1"
}
test_inc

// Tests the decrement function, i.e. which perform x-=dx
proc test_dec {
    proc assert_dec x:Int dx:Int exp:Int name:Tape {
        dec x dx
        assert_int_eq x exp name
    }

    assert_dec (Int "1") (Int "0") (Int "1") "1-=0"
    assert_dec (Int "1") (Int "1") (Int "0") "1-=1"
    assert_dec (Int "1011") (Int "0110") (Int "11100") "1101-=110"
}
test_dec