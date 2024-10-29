use "random"
use "collections"

actor ChordNode
  let _id: U64
  let _hop_counter: HopCounter tag
  var _predecessor: U64
  var _successor: U64
  var _finger_table: Array[U64]
  var _total_hops: U64
  var _requests: U64
  var _m: U64
  var _max_requests: U64
  var _total_space: U64
  let _env: Env
  var _stabilize_count: U64 = 0
  let _max_stabilize_rounds: U64 = 5

  new create(id: U64, m: U64, max_requests: U64, hop_counter: HopCounter tag, 
    total_space: U64, env: Env) =>
    _id = id
    _m = m
    _max_requests = max_requests
    _hop_counter = hop_counter
    _finger_table = Array[U64].init(0, m.usize())
    _total_space = total_space
    _predecessor = id  // Initialize with self
    _successor = id    // Initialize with self
    _total_hops = 0
    _requests = 0
    _env = env
    _initialize_finger_table()

  be initialize() =>
    if not verify_finger_table() then
      _env.out.print("Node " + _id.string() + " has invalid finger table entries")
      _initialize_finger_table()
    end
    this.stabilize()

  be start_query() =>
    if _requests < _max_requests then
      _requests = _requests + 1
      this.query_request()
    else
      // _env.out.print("Node " + _id.string() + " has completed " + _requests.string() + 
      //   " requests with " + _total_hops.string() + " total hops.")
      _hop_counter.node_converged(_id, _total_hops, _requests)
    end

  be query_request() =>
    let rand = Rand
    let key = rand.int[U64](_total_space)
    // _env.out.print("Node " + _id.string() + " is querying for key " + key.string())
    this.find_next_key(_id, key, 0)
    
  be find_next_key(start_node_id: U64, id: U64, hops: U64) =>
    try
      if id == _id then
        _total_hops = _total_hops + hops
        // _env.out.print("Node " + _id.string() + " has found the key " + id.string() + 
        //   " with " + hops.string() + " hops.")
        _hop_counter.found_key(start_node_id, hops)
        this.start_query()
      else
        let successor = _finger_table(0)?
        if this.in_between(_id, id, successor, true) then
          _total_hops = _total_hops + hops
          // _env.out.print("Node " + _id.string() + " has found the key " + id.string() + 
          //   " at its successor.")
          _hop_counter.found_key(start_node_id, hops)
          this.start_query()
        else
          this.forward_to_finger(id, start_node_id, hops)
        end
      end
    else
      //_env.out.print("Error in find_next_key for node " + _id.string())
      this.start_query()
    end

  be join_ring(existing_node: ChordNode tag) =>
    _predecessor = _id  // Initialize with self
    _successor = _id    // Initialize with self
    existing_node.search_next_node(_id, this)
    // _env.out.print("Node " + _id.string() + " joining the ring.")

  be search_next_node(id: U64, new_node: ChordNode tag) =>
    try
      let successor = _finger_table(0)?
      if this.in_between(_id, id, successor, true) then
        // _env.out.print("Node " + _id.string() + " has found the next node " + successor.string())
        new_node.set_successor(successor)
        this.update_predecessor(id)
      else
        this.forward_find_successor(id, new_node)
      end
    end
    //else
      // _env.out.print("Error in search_next_node for node " + _id.string())
    //end

  be set_successor(successor_id: U64) =>
    _successor = successor_id
    try
      _finger_table.update(0, successor_id)?
      this.fix_fingers(1)
    end

  be update_predecessor(new_pred: U64) =>
    _predecessor = new_pred

be stabilize() =>
  if _stabilize_count < _max_stabilize_rounds then
    try
      let successor = _finger_table(0)?
      // _env.out.print("Node " + _id.string() + " is stabilizing with successor " + 
      //   successor.string())
      _hop_counter.receive_node(successor, this)
      _stabilize_count = _stabilize_count + 1
    end
  end

  be fix_fingers(i: USize) =>
    try
      if i < _m.usize() then
        let next_finger = (_id + (1 << i.u64())) % _total_space
        let current = _finger_table(i)?
        if this.in_between(_id, next_finger, current, true) then
          _finger_table.update(i, next_finger)?
          
        end
        this.fix_fingers(i + 1)
        //for va in Range(0,_finger_table.size())do
        // _env.out.print(_id.string()+" ->"+_finger_table(va)?.string())
        //end
      end
    end

  fun ref forward_to_finger(id: U64, start_node_id: U64, hops: U64) =>
    try
      var closest_preceding_node = _id
      var closest_distance = _total_space
      
      // Find the closest preceding finger
      for i in Range[USize](_m.usize(), 0, -1) do
        let finger = _finger_table(i-1)?
        let finger_distance = if finger > id then
          _total_space - (finger - id)
        else
          id - finger
        end
        
        if this.in_between(_id, finger, id, false) and (finger_distance < closest_distance) then
          closest_preceding_node = finger
          closest_distance = finger_distance
        end
      end
      
      // If no better finger found, forward to immediate successor
      if closest_preceding_node == _id then
        let successor = _finger_table(0)?
        // _env.out.print("Node " + _id.string() + " forwarding request to successor " + 
        //   successor.string())
        _hop_counter.forward_request(successor, start_node_id, id, hops + 1)
      else
        // _env.out.print("Node " + _id.string() + " forwarding request to optimized finger " + 
        //   closest_preceding_node.string())
        _hop_counter.forward_request(closest_preceding_node, start_node_id, id, hops + 1)
      end
    //else
      // _env.out.print("Error: Node " + _id.string() + " has incomplete finger table")
    end

  fun ref forward_find_successor(id: U64, new_node: ChordNode tag) =>
    try
      var closest_preceding_node = _id
      var closest_distance = _total_space
      
      for i in Range[USize](_m.usize(), 0, -1) do
        let finger = _finger_table(i-1)?
        if this.in_between(_id, finger, id, false) then
          closest_preceding_node = finger
          break
        end
      end
      
      if closest_preceding_node == _id then
        let successor = _finger_table(0)?
        _hop_counter.forward_find_successor(successor, id, new_node)
      else
        _hop_counter.forward_find_successor(closest_preceding_node, id, new_node)
      end
    end

  fun ref in_between(left: U64, value: U64, right: U64, include_right: Bool): Bool =>
    if left == right then
      return include_right and (value == right)
    end

    let normalized_right = if right < left then right + _total_space else right end
    let normalized_value = if value < left then value + _total_space else value end
    
    let basic_check = (normalized_value > left) and (normalized_value < normalized_right)
    let boundary_check = include_right and (normalized_value == normalized_right)
    
    basic_check or boundary_check

  fun ref verify_finger_table(): Bool =>
    try
      for i in Range[USize](0, _m.usize()) do
        let finger = _finger_table(i)?
        if finger >= _total_space then
          // _env.out.print("Invalid finger table entry at index " + i.string())
          return false
        end
      end
      true
    else
      false
    end

  fun ref _initialize_finger_table() =>
    try
      for i in Range[USize](0, _m.usize()) do
        _finger_table.update(i, (_id + (1 << i.u64())) % _total_space)?
      end
      for i in Range[USize](0, _m.usize()) do
        let finger = _finger_table(i)?
        end
    end

  be send_id(requester: HopCounter, node_id: U64) =>
    requester.receive_id(_id, node_id)

actor HopCounter
  var _total_hops: U64
  var _total_requests: U64
  var _converged_nodes: U64
  let _num_nodes: U64
  let _nodes: Array[ChordNode tag]
  let _env: Env
  var _stabilization_rounds: U64 = 0
  let _max_stabilization_rounds: U64 = 5

  new create(num_nodes: U64, env: Env) =>
    _num_nodes = num_nodes
    _nodes = Array[ChordNode tag]
    _total_hops = 0
    _total_requests = 0
    _converged_nodes = 0
    _env = env

  be node_converged(id: U64, hops: U64, requests: U64) =>
    _total_hops = _total_hops + hops
    _total_requests = _total_requests + requests
    _converged_nodes = _converged_nodes + 1
    // _env.out.print("Node " + id.string() + " has converged with " + hops.string() + 
    //   " total hops and " + requests.string() + " requests.")
    if _converged_nodes == 1 then
      this.print_stats()
    end

  fun print_stats() =>
    let avg_hops = _total_hops.f64() / _total_requests.f64()
    _env.out.print("\nFinal Statistics:")
    _env.out.print("Total nodes: " + _num_nodes.string())
    _env.out.print("Total requests: " + _total_requests.string())
    _env.out.print("Total hops: " + _total_hops.string())
    _env.out.print("Average hops per request: " + avg_hops.string())

  be found_key(start_node_id: U64, hops: U64) =>
    _env.out.print("Key found by node " + start_node_id.string() + " after " + 
      hops.string() + " hops.")

  be forward_request(finger: U64, start_node_id: U64, id: U64, hops: U64) =>
    try
      _nodes(finger.usize())?.find_next_key(start_node_id, id, hops)
    else
      _env.out.print("Error: Unable to forward request to node " + finger.string())
    end

  be forward_find_successor(node_id: U64, target_id: U64, new_node: ChordNode tag) =>
    try
      _nodes(node_id.usize())?.search_next_node(target_id, new_node)
    end

  be receive_node(node_id: U64, sender: ChordNode tag) =>
    try
      _nodes(node_id.usize())?.stabilize()
    end

  be add_node(node: ChordNode tag) =>
    _nodes.push(node)
    _env.out.print("Added node to the network")

  be receive_id(node_id: U64, requesting_node_id: U64) =>
    _env.out.print("Node " + node_id.string() + " identified")

actor Main
  new create(env: Env) =>
    try
      let num_nodes = env.args(1)?.u64()?
      let num_requests = env.args(2)?.u64()?
      let m: U64 = 20
      let total_space: U64 = (1 << m)

      let hop_counter = HopCounter(num_nodes, env)
      let nodes = Array[ChordNode tag]
      let node_ids = Set[U64]

      // Create first node
      let first_node = ChordNode(0, m, num_requests, hop_counter, total_space, env)
      nodes.push(first_node)
      hop_counter.add_node(first_node)

      // Create remaining nodes with random IDs
      let rand = Rand
      var created_nodes: U64 = 1
      while created_nodes < num_nodes do
        let node_id = rand.int[U64](total_space)
        if not node_ids.contains(node_id) then
          node_ids.set(node_id)
          let node = ChordNode(node_id, m, num_requests, hop_counter, total_space, env)
          nodes.push(node)
          hop_counter.add_node(node)
          created_nodes = created_nodes + 1
        end
      end

      // Initialize and join nodes to the ring
      for i in Range(1, nodes.size()) do
        try
          nodes(i)?.join_ring(first_node)
          nodes(i)?.initialize()
        end
      end

      // Start the queries after a brief delay to allow stabilization
      for node in nodes.values() do
        node.start_query()
      end

    else
      env.out.print("Usage: " + try env.args(0)? else "chord" end + 
        " <num_nodes> <num_requests>")
    end