# Troubleshooting Known Issues

## Submodule errors on updating

> NOTE: This problem **should never occur** unless your first clone was before Sept. 15, 2019 ([55771bc](https://github.com/chiphogg/vim-vtd/commit/55771bc)).

When you try to update `vim-vtd`, you may find that the submodules fail to update.  Here's an example error message, based on the commands that vundle runs under the hood:

```
$ cd '/home/chogg/.vim/bundle/vim-vtd' && git pull && git submodule update --init --recursive
> Updating a4920a1..55771bc
> Fast-forward
>  python/libvtd | 2 +-
>  1 file changed, 1 insertion(+), 1 deletion(-)
> Submodule path 'python/libvtd': checked out 'b93be3f1bacb2d9289042a4d090fb789de48ba5e'
> error: Server does not allow request for unadvertised object 03fa92bfedbe020724de5dde8864e3a9539162b4
> Fetched in submodule path 'python/libvtd/third_party/dateutil', but it did not contain 03fa92bfedbe020724de5dde8864e3a9539162b4. Direct fetching of that commit failed.
> Failed to recurse into submodule path 'python/libvtd'
```

This is tracked in [VundleVim/Vundle.vim#911](https://github.com/VundleVim/Vundle.vim/911).

### The fix

If your error message looks similar to this, you can fix this by changing into the `vim-vtd/` folder and running the following commands:

```sh
git submodule sync --recursive
```

After you do this, you can run your other `git submodule` commands.  (If you use vundle, `:PluginUpdate` will now work; or, you can now run `git submodule update --init --recursive` directly if you choose.)
