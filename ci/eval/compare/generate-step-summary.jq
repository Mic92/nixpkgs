def truncate_document(content; n):
  if content | utf8bytelength > n then content[:n] + "..."
  else content
  end;

def itemize_packages(xs):
  map("- [\(.)](https://search.nixos.org/packages?channel=unstable&show=\(.)&from=0&size=50&sort=relevance&type=packages&query=\(.))") | join("\n");

def section(title; xs):
  "<details> <summary>" + title + " (" + (xs | length | tostring) + ")</summary>\n\n" + itemize_packages(xs) + "</details>";

# we truncate the list to stay below the GitHub limit of 1MB per step summary.
truncate_document(
  section("Added packages"; .attrdiff.added) + "\n\n" +
  section("Removed packages"; .attrdiff.removed) + "\n\n" +
  section("Changed packages"; .attrdiff.changed); (1024 * 1024 - 3)
)
