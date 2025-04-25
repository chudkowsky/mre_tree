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
from starkware.cairo.common.math_cmp import is_le_felt
from starkware.cairo.common.segments import relocate_segment

//test flow should look like this: user provides array, we filter it, we sort it, we add zeros if needed, we hash it

func main{output_ptr: felt*, range_check_ptr, poseidon_ptr: PoseidonBuiltin*}() {
    alloc_locals;
    
    let (slots: felt*) = alloc();
    local slots_len;
    
    %{
    with open('numbers.txt', 'r') as file:
        numbers = [int(line.strip()) for line in file]
    slots_len = len(numbers)
    ids.slots_len = slots_len;
    for i in range(slots_len):
        memory[ids.slots+i] = numbers[i]
    %}

    print_array(array=slots, array_len=slots_len);
    
    let (filtered_slots: felt*) = alloc();
    let filtered_slots_len = 0;

    filter_slots{filtered_slots=filtered_slots, filtered_slots_len=filtered_slots_len}(
        slots=slots, slots_len=slots_len
    );
    local sorted_array : felt*;
    let (is_sorted) = is_sorted_recursively(array=filtered_slots, array_len=filtered_slots_len, index=0);

    if (is_sorted == 0) {
        let temp = sort_array(array=filtered_slots, array_len=filtered_slots_len);
        sorted_array = temp;
        let (is_sorted) = is_sorted_recursively(array=sorted_array, array_len=filtered_slots_len, index=0);
        assert is_sorted = 1;
        tempvar range_check_ptr = range_check_ptr;
    }else{
        sorted_array = filtered_slots;        
        tempvar range_check_ptr = range_check_ptr;
    }

    tempvar range_check_ptr = range_check_ptr;

    let next_power_of_2 = log2_ceil(filtered_slots_len);
    let (next_power_of_2_value) = pow(2, next_power_of_2);

    if (next_power_of_2_value != filtered_slots_len) {
        let added_zeros = 0;
        let array = &sorted_array[filtered_slots_len];
        add_zeros{array=array, added_zeros=added_zeros}(
            zeros_to_add=next_power_of_2_value - filtered_slots_len
        );
        assert added_zeros = next_power_of_2_value - filtered_slots_len;
    }

    let filtered_slots_len = next_power_of_2_value;

    print_array(array=sorted_array, array_len=filtered_slots_len);
    let (hash_tree) = merkle_tree_hash(array=sorted_array, array_len=filtered_slots_len);
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

// Function to check if an array is sorted in ascending order recursively
func is_sorted_recursively{range_check_ptr}(array: felt*, array_len: felt, index: felt) -> (is_sorted: felt) {
    // Base case: if we have reached the second last element
    if (index == array_len - 1) {
        return (is_sorted=1);
    }
    let x = is_le_felt(array[index], array[index + 1]);

    if (x == 0) {
        return (is_sorted=0);
    }

    // Recurse for the rest of the array
    return is_sorted_recursively(array=array, array_len=array_len, index=index + 1);
}

func print_array(array: felt*, array_len: felt) {
    %{
        dlugosc=ids.array_len 
        print("dlugosc: ", dlugosc)
        for i in range(dlugosc):
            print(memory[ids.array+i])
        print("--------------------------------")
    %}
    return ();
}

func sort_array(array: felt*, array_len: felt) -> felt* {
    let (sorted_array: felt*) = alloc();
    %{
        array_len = ids.array_len
        array = []
        for i in range(array_len):
            array.append(memory[ids.array+i])
        array.sort()
        for i in range(array_len):
            memory[ids.sorted_array+i] = array[i]
    %}

    return sorted_array;
}