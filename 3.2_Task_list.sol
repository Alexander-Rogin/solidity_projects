pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;

contract TaskList {

	struct TaskInfo {
		string taskName;
		uint32 timeAdded;
		bool isCompleted;
	}

	mapping(int8 => TaskInfo) tasks;
	int8 last_key = 0;

	constructor() public {
		// check that contract's public key is set
		require(tvm.pubkey() != 0, 101);
		// Check that message has signature (msg.pubkey() is not zero) and message is signed with the owner's private key
		require(msg.pubkey() == tvm.pubkey(), 102);
		tvm.accept();
	}

	// Modifier that allows to accept some external messages
	modifier checkOwnerAndAccept {
		// Check that message was signed with contracts key.
		require(msg.pubkey() == tvm.pubkey(), 102);
		tvm.accept();
		_;
	}

	function add_task(string taskName, bool isCompleted) public checkOwnerAndAccept {
		tasks[last_key] = TaskInfo(taskName, now, isCompleted);
		last_key++;
	}

	function get_open_task_count() public checkOwnerAndAccept returns (int8) {
		int8 open_task_count = 0;
		for (int8 i = 0; i < last_key; i++) {
			if (tasks[i].taskName != "" && !tasks[i].isCompleted) {
				open_task_count++;
			}
		}
		return open_task_count;
	}

	function get_tasks() public checkOwnerAndAccept returns (TaskInfo[]) {
		TaskInfo[] taskList;
		for (int8 i = 0; i < last_key; i++) {
			if (tasks[i].taskName != "") {
				taskList.push(tasks[i]);
			}
		}
		return taskList;
	}

	function get_task(int8 key) public checkOwnerAndAccept returns (TaskInfo) {
		return tasks[key];
	}

	function delete_task(int8 key) public checkOwnerAndAccept {
		delete tasks[key];
	}

	function complete_task(int8 key) public checkOwnerAndAccept {
		tasks[key].isCompleted = true;
	}
}
