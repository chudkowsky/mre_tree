%builtins output poseidon

from starkware.cairo.common.serialize import serialize_word
from starkware.cairo.common.cairo_builtins import PoseidonBuiltin
from starkware.cairo.common.builtin_poseidon.poseidon import poseidon_hash_single, poseidon_hash_many, poseidon_hash
from starkware.cairo.common.alloc import alloc


func main{output_ptr: felt*,poseidon_ptr: PoseidonBuiltin*}() {
    alloc_locals;
    let (slots: felt*) = alloc();
    
    
    assert slots[0] = 3;
    assert slots[1] = 7;
    assert slots[2] = 3;
    assert slots[3] = 4;
    assert slots[4] = 5;
    assert slots[5] = 6;
    assert slots[6] = 7;
    assert slots[7] = 8;
    let slots_len = 2;

    let (hash_tree) = merkle_tree_hash(array=slots, array_len=slots_len);
    local hash_tree = hash_tree;
     
    serialize_word(hash_tree);

    return ();

}

func merkle_tree_hash{poseidon_ptr: PoseidonBuiltin*}(array: felt*, array_len: felt) -> (res: felt) {
    alloc_locals;
    if (array_len == 1) {
        return poseidon_hash_many(1, array);  
    }
    
    let (left) = merkle_tree_hash(array=array, array_len=array_len / 2);
    local left = left;

    let (right) = merkle_tree_hash(array=&array[array_len/2], array_len=array_len / 2);
    local right = right;

    let (new_array) = alloc();
    new_array[0] = left;
    new_array[1] = right;

    let (res) = poseidon_hash_many(2, new_array);
    local res = res;
    return (res=res);
}
