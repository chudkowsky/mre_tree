%builtins output range_check poseidon

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.cairo_builtins import PoseidonBuiltin
from starkware.cairo.common.builtin_poseidon.poseidon import (
    poseidon_hash_single,
    poseidon_hash_many,
    poseidon_hash,
)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.log2_ceil import log2_ceil
from starkware.cairo.common.pow import pow

func main{output_ptr: felt*, range_check_ptr, poseidon_ptr: PoseidonBuiltin*}() {
    alloc_locals;
    let (slots: felt*) = alloc();
    assert slots[0] = 0;
    assert slots[1] = 7;
    assert slots[2] = 3;
    assert slots[3] = 4;
    assert slots[4] = 5;
    assert slots[5] = 6;
    assert slots[6] = 7;
    assert slots[7] = 0;
    assert slots[8] = 0;
    let slots_len = 9;

    let (filtered_slots: felt*) = alloc();
    let filtered_slots_len = 0;
    filter_slots{filtered_slots=filtered_slots, filtered_slots_len=filtered_slots_len}(
        slots=slots, slots_len=slots_len
    );

    let next_power_of_2 = log2_ceil(filtered_slots_len);
    let (next_power_of_2_value) = pow(2, next_power_of_2);

    if (next_power_of_2_value != filtered_slots_len) {
        let added_zeros = 0;
        let array = &filtered_slots[filtered_slots_len];
        add_zeros{array=array, added_zeros=added_zeros}(
            zeros_to_add=next_power_of_2_value - filtered_slots_len
        );
        assert added_zeros = next_power_of_2_value - filtered_slots_len;
    }

    let filtered_slots_len = next_power_of_2_value;
    let (hash_tree) = merkle_tree_hash(array=filtered_slots, array_len=filtered_slots_len);
    local hash_tree = hash_tree;

    serialize_word(hash_tree);

    return ();
}

//Dummy function to replicate the behaviour in snos where we filter some data
func filter_slots{filtered_slots: felt*, filtered_slots_len: felt}(slots: felt*, slots_len: felt) {
    alloc_locals;
    if (slots_len == 0) {
        return ();
    }

    let element = slots[0];

    if (element != 0) {
        assert filtered_slots[filtered_slots_len] = element;  // Write directly to the current position
        let next_len = filtered_slots_len + 1;
        return filter_slots{filtered_slots=filtered_slots, filtered_slots_len=next_len}(
            slots=&slots[1], slots_len=slots_len - 1
        );
    }

    return filter_slots{filtered_slots=filtered_slots, filtered_slots_len=filtered_slots_len}(
        slots=&slots[1], slots_len=slots_len - 1
    );
}
// Function to add zeros to the array to make it a power of 2
func add_zeros{array: felt*, added_zeros: felt}(zeros_to_add: felt) {
    if (zeros_to_add == 0) {
        return ();
    }

    assert array[added_zeros] = 0;
    let next_added_zeros = added_zeros + 1;
    return add_zeros{array=array, added_zeros=next_added_zeros}(zeros_to_add=zeros_to_add - 1);
}

// Function to hash the array to get the merkle root
func merkle_tree_hash{poseidon_ptr: PoseidonBuiltin*}(array: felt*, array_len: felt) -> (
    res: felt
) {
    alloc_locals;
    if (array_len == 1) {
        return poseidon_hash_many(1, array);
    }

    let (left) = merkle_tree_hash(array=array, array_len=array_len / 2);
    local left = left;

    let (right) = merkle_tree_hash(array=&array[array_len / 2], array_len=array_len / 2);
    local right = right;

    let (new_array) = alloc();
    new_array[0] = left;
    new_array[1] = right;

    let (res) = poseidon_hash_many(2, new_array);
    local res = res;
    return (res=res);
}
