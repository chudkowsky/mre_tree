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

struct Crdt {
    key: felt,
    type: felt,
}

func main{output_ptr: felt*, range_check_ptr, poseidon_ptr: PoseidonBuiltin*}() {
    alloc_locals;

    let (slots: Crdt*) = alloc();
    local slots_len;
    assert slots[0] = Crdt(key=0, type=1);
    assert slots[1] = Crdt(key=1, type=2);
    assert slots[2] = Crdt(key=2, type=1);
    assert slots[3] = Crdt(key=3, type=3);
    assert slots[4] = Crdt(key=123, type=2);
    assert slots[5] = Crdt(key=5, type=1);
    assert slots[6] = Crdt(key=6, type=3);
    assert slots[7] = Crdt(key=7, type=2);
    slots_len = 8;
    print_array(array=slots, array_len=slots_len);

    local sorted_array : felt*;
    let (is_sorted) = is_sorted_recursively(array=slots, array_len=slots_len, index=0);

    if (is_sorted == 0) {
        %{print("is not sorted")%}
        let temp = sort_array(array=slots, array_len=slots_len);
        sorted_array = temp;
        print_array(array=sorted_array, array_len=slots_len);
        tempvar range_check_ptr = range_check_ptr;
    } else {
    %{print("is sorted")%}
        sorted_array = slots;        
        tempvar range_check_ptr = range_check_ptr;
    }

    tempvar range_check_ptr = range_check_ptr;

    // let next_power_of_2 = log2_ceil(slots_len);
    // let (next_power_of_2_value) = pow(2, next_power_of_2);

    // if (next_power_of_2_value != slots_len) {
    //     let added_zeros = 0;
    //     let array = &sorted_array[slots_len];
    //     add_zeros{array=array, added_zeros=added_zeros}(
    //         zeros_to_add=next_power_of_2_value - slots_len
    //     );
    //     assert added_zeros = next_power_of_2_value - slots_len;
    // }

    // let filtered_slots_len = next_power_of_2_value;

    // print_array(array=sorted_array, array_len=filtered_slots_len);
    // let (hash_tree) = merkle_tree_hash(array=sorted_array, array_len=filtered_slots_len);
    // local hash_tree = hash_tree;

    // serialize_word(hash_tree);
    
    return ();
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
    let x = is_le_felt(array[index*2], array[(index + 1)*2]);

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
            print("key: ", memory[ids.array+2*i], end=" ")
            print("type: ", memory[ids.array+2*i+1])
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


func count_occurrences{range_check_ptr}(array: felt*, array_len: felt, element: felt) -> (count: felt) {
    if (array_len == 0) {
        return (count=0);
    }

    if (array[0] == element) {
        let (rest_count) = count_occurrences(array=array + 1, array_len=array_len - 1, element=element);
        return (count=1 + rest_count);
    } else {
        return count_occurrences(array=array + 1, array_len=array_len - 1, element=element);
    }
}


// // Function to verify that two arrays contain exactly the same elements
// func verify_same_elements{range_check_ptr}(array1: felt*, array2: felt*, len: felt) -> (is_same: felt) {
//     if (len == 0) {
//         return (is_same=1);
//     }

//     // Check if current element exists in array2
//     let element = array1[0];
//     let (found) = element_exists_in_array(array2, len, element);
    
//     if (found == 0) {
//         return (is_same=0);
//     }

//     // Check if array2 element exists in array1
//     let element2 = array2[0];
//     let (found2) = element_exists_in_array(array1, len, element2);
    
//     if (found2 == 0) {
//         return (is_same=0);
//     }

//     // Check rest of the arrays
//     return verify_same_elements(array1=array1 + 1, array2=array2 + 1, len=len - 1);
// }

// // Helper function to check if element exists in array
// func element_exists_in_array{range_check_ptr}(array: felt*, len: felt, element: felt) -> (exists: felt) {
//     if (len == 0) {
//         return (exists=0);
//     }

//     if (array[0] == element) {
//         return (exists=1);
//     }

//     return element_exists_in_array(array=array + 1, len=len - 1, element=element);
// }
