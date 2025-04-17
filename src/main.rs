use cairo_vm::{
    cairo_run::CairoRunConfig, hint_processor::{builtin_hint_processor::builtin_hint_processor_definition::BuiltinHintProcessor, cairo_1_hint_processor::hint_processor::Cairo1HintProcessor, hint_processor_definition::HintProcessor}, types::program::Program, vm::runners::cairo_runner::CairoRunner
};

fn main() {
    println!("Hello, world!");
}

pub fn run_cairo_0_program() {
    let program_content = include_bytes!("../compiled.json");
    let cairo_run_config = CairoRunConfig {
        layout: cairo_vm::types::layout_name::LayoutName::recursive,
        relocate_mem: true,
        trace_enabled: true,
        ..Default::default()
    };
    let program = Program::from_bytes(program_content, Some(cairo_run_config.entrypoint)).unwrap();
    let mut cairo_runner = CairoRunner::new(
        &program,
        cairo_run_config.layout,
        cairo_run_config.proof_mode,
        cairo_run_config.trace_enabled,
    )
    .unwrap();
    let end = cairo_runner.initialize(false).unwrap();
}

pub struct MREHintProcessor{
    builting_hint_proc: BuiltinHintProcessor,
    cairo1_builtin_hint_proc: Cairo1HintProcessor,

};

impl HintProcessor for MREHintProcessor {
   
}