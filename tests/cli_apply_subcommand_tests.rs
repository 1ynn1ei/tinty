mod utils;

use crate::utils::{
    read_file_to_string, setup, write_to_file, CURRENT_SCHEME_FILE_NAME, REPO_NAME,
};
use anyhow::Result;

#[test]
fn test_cli_apply_subcommand_with_setup() -> Result<()> {
    // -------
    // Arrange
    // -------
    let scheme_name = "base16-oceanicnext";
    let (config_path, data_path, command_vec, cleanup) = setup(
        "test_cli_apply_subcommand_with_setup",
        format!("apply {}", &scheme_name).as_str(),
    )?;
    let shell_theme_filename = "base16-shell-scripts-file.sh";
    let current_scheme_path = data_path.join(CURRENT_SCHEME_FILE_NAME);

    // ---
    // Act
    // ---
    utils::run_install_command(&config_path, &data_path)?;
    let (stdout, _) = utils::run_command(command_vec).unwrap();

    // ------
    // Assert
    // ------
    assert!(
        stdout.is_empty(),
        "stdout does not contain the expected output"
    );
    assert!(
        data_path.join(shell_theme_filename).exists(),
        "Path does not exist"
    );
    assert_eq!(read_file_to_string(&current_scheme_path)?, scheme_name);

    cleanup()?;
    Ok(())
}

#[test]
fn test_cli_apply_subcommand_without_setup() -> Result<()> {
    // -------
    // Arrange
    // -------
    let scheme_name = "base16-oceanicnext";
    let (_, _, command_vec, cleanup) = setup(
        "test_cli_apply_subcommand_without_setup",
        format!("apply {}", &scheme_name).as_str(),
    )?;
    let expected_output = format!(
        "Schemes do not exist, run install and try again: `{} install`",
        REPO_NAME
    );

    // ---
    // Act
    // ---
    let (_, stderr) = utils::run_command(command_vec).unwrap();

    // ------
    // Assert
    // ------
    assert!(
        stderr.contains(&expected_output),
        "stderr does not contain the expected output"
    );

    cleanup()?;
    Ok(())
}

#[test]
fn test_cli_apply_subcommand_invalid_scheme_name() -> Result<()> {
    // -------
    // Arrange
    // -------
    let scheme_name = "base16-invalid-scheme";
    let (config_path, data_path, command_vec, cleanup) = setup(
        "test_cli_apply_subcommand_invalid_scheme_name",
        format!("apply {}", &scheme_name).as_str(),
    )?;
    let expected_output = format!("Scheme does not exist: {}", scheme_name);

    // ---
    // Act
    // ---
    utils::run_install_command(&config_path, &data_path)?;
    let (_, stderr) = utils::run_command(command_vec).unwrap();

    // ------
    // Assert
    // ------
    assert!(
        stderr.contains(&expected_output),
        "stderr does not contain the expected output"
    );

    cleanup()?;
    Ok(())
}

#[test]
fn test_cli_apply_subcommand_invalid_scheme_system() -> Result<()> {
    // -------
    // Arrange
    // -------
    let scheme_name = "some-invalid-scheme";
    let (_, _, command_vec, cleanup) = setup(
        "test_cli_apply_subcommand_invalid_scheme_system",
        format!("apply {}", &scheme_name).as_str(),
    )?;
    let expected_output = format!("Invalid scheme name. Make sure your scheme is prefixed with a supprted system (\"base16\" or \"base24\"), eg: base16-{}", scheme_name);

    // ---
    // Act
    // ---
    let (_, stderr) = utils::run_command(command_vec).unwrap();

    // ------
    // Assert
    // ------
    cleanup()?;
    assert!(
        stderr.contains(&expected_output),
        "stderr does not contain the expected output"
    );

    Ok(())
}

#[test]
fn test_cli_apply_subcommand_no_scheme_system() -> Result<()> {
    // -------
    // Arrange
    // -------
    let scheme_name = "ocean";
    let (_, _, command_vec, cleanup) = setup(
        "test_cli_apply_subcommand_no_scheme_system",
        format!("apply {}", &scheme_name).as_str(),
    )?;
    let expected_output = "Invalid scheme name. Make sure the scheme system is prefixed <SCHEME_SYSTEM>-<SCHEME_NAME>, eg: `base16-ayu-dark`";

    // ---
    // Act
    // ---
    let (_, stderr) = utils::run_command(command_vec).unwrap();

    // ------
    // Assert
    // ------
    cleanup()?;
    assert!(
        stderr.contains(&expected_output),
        "stderr does not contain the expected output"
    );

    Ok(())
}

#[test]
fn test_cli_apply_subcommand_root_hooks_with_setup() -> Result<()> {
    // -------
    // Arrange
    // -------
    let scheme_name = "base16-oceanicnext";
    let (config_path, data_path, command_vec, cleanup) = setup(
        "test_cli_apply_subcommand_with_setup",
        format!("apply {}", &scheme_name).as_str(),
    )?;
    let expected_output = "This\nis\nexpected\noutput.";
    let config_content = r##"
hooks = ["echo 'This '", "echo 'is '", "echo 'expected '", "echo 'output.'"]
"##;
    write_to_file(&config_path, config_content)?;

    // ---
    // Act
    // ---
    utils::run_install_command(&config_path, &data_path)?;
    let (stdout, stderr) = utils::run_command(command_vec).unwrap();

    // ------
    // Assert
    // ------
    assert!(
        stdout.contains(expected_output),
        "stdout does not contain the expected output"
    );
    assert!(
        stderr.is_empty(),
        "stderr does not contain the expected output"
    );

    cleanup()?;
    Ok(())
}

#[test]
fn test_cli_apply_subcommand_hook_with_setup() -> Result<()> {
    // -------
    // Arrange
    // -------
    let scheme_name = "base16-oceanicnext";
    let (config_path, data_path, command_vec, cleanup) = setup(
        "test_cli_apply_subcommand_with_setup",
        format!("apply {}", &scheme_name).as_str(),
    )?;
    let config_content = r##"
[[items]]
path = "https://github.com/tinted-theming/base16-vim"
name = "tinted-vim"
themes-dir = "colors"
hook = "echo \"path: %f\""
"##;
    write_to_file(&config_path, config_content)?;

    // ---
    // Act
    // ---
    utils::run_install_command(&config_path, &data_path)?;
    let (stdout, stderr) = utils::run_command(command_vec).unwrap();

    // ------
    // Assert
    // ------
    assert!(
        stdout
            .contains(format!("path: {}/tinted-vim-colors-file.vim", data_path.display()).as_str()),
        "stdout does not contain the expected output"
    );
    assert!(
        stderr.is_empty(),
        "stderr does not contain the expected output"
    );

    cleanup()?;
    Ok(())
}
