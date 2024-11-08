package sl

import "core:fmt"
import "core:strings"
import rl "vendor:raylib"


@private quick_bms:map[string]f64

@private init_benchmarks :: proc() {
	quick_bms = make(map[string]f64)
}

@private destroy_benchmarks :: proc() {
	assert(len(quick_bms) == 0)
	delete(quick_bms)
}

@private _quick_benchmark_start :: proc(name:string) {
	quick_bms[name] = rl.GetTime()
}

@private _quick_benchmark_stop :: proc(name:string) {
	t2:f64 = rl.GetTime() // get 't2' first, even if name ends up being invalid

	if name not_in quick_bms {
		__WARNING("'%s' doesn't exist in quick benchmarks", name)
		return
	}

	t1:f64 = quick_bms[name]

	fmt.printf("%s: %fms\n", name, (t2-t1)*1000)
	delete_key(&quick_bms, name)
}

// BenchmarkData :: struct {
// 	name:string,
// 	t1:f64,
// 	t2:f64,
// }


// benchmark_new :: proc(name:="") -> ^BenchmarkData {
// 	return BenchmarkData{name}
// }

// benchmark_start :: proc(t:^BenchmarkData) {
// 	t.t1 = rl.GetTime()
// }



// benchmark_stop :: proc(timer:BenchmarkData) {
// 	t.t2 = rl.GetTime()
// 	fmt.println(t.name, t.t2-t.t1)
// }

