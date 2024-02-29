import click
import invoke


@invoke.task
def trash_empty_files(c):
    from pathlib import Path

    cwd = Path()

    # print(cwd)

    iterator = cwd.iterdir()

    files = [ f for f in iterator if f.is_file() ]

    # print(files)

    def is_file_empty(path):
        return path.is_file() and path.stat().st_size == 0

    empty_files = [ f for f in files if is_file_empty(f) ]

    for file in empty_files:
        # print(file)
        with open(file) as f:
            content = f.read()

        components = [
                f'File: {file}',
                f'Size: {file.stat().st_size}',
                f'Content: {content}',
        ]

        message = '\n'.join(components)

        click.echo(click.style(message, dim=True))

    click.echo(click.style('ATTENTION!', blink=True))

    confirmed = click.confirm("Would you like to delete the empty files above?")

    def trash(path):
        command = f"""
        osascript -e 'tell app "Finder" to delete POSIX file "{path.resolve()}"'
        """

        # print(command)

        c.run(command, hide=True)

    if confirmed:
        click.echo(click.style('Deleting...', bold=True))

        with click.progressbar(empty_files) as bar:
            for empty_file in bar:
                click.echo(click.style(f' Trashing {empty_file}', dim=True))
                trash(empty_file)
    else:
        click.echo(click.style('Cancelled...', dim=True))



# Files namespace


files = invoke.Collection('files')

files.add_task(trash_empty_files, 'trash_empty')

# Root namespace


namespace = invoke.Collection()

namespace.add_collection(files)
