class RocketReview < Formula
  include Language::Python::Virtualenv

  desc "Second-opinion code and plan reviews from Codex, Claude Code, or opencode"
  homepage "https://github.com/ledger-rocket/rocket-review"
  url "https://files.pythonhosted.org/packages/1d/5c/6166c05aca15cfdcf96a9045404b052615a7870f4c82498e2e4a532d9de9/rocket_review-0.3.1.tar.gz"
  sha256 "29190a989e02d28e14af19df2937da917306c3b40e920d8cc00fffc1c50d58fa"
  license "Apache-2.0"

  depends_on "python@3.13"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rr --version")
  end
end
