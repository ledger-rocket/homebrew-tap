class RocketReview < Formula
  include Language::Python::Virtualenv

  desc "Second-opinion code and plan reviews from Codex, Claude Code, or opencode"
  homepage "https://github.com/ledger-rocket/rocket-review"
  url "https://files.pythonhosted.org/packages/88/29/8c476c4b1f42aee362974466e14d11f73d39cd92b71e673c7144a1ea2725/rocket_review-0.6.0.tar.gz"
  sha256 "3e26478079ca8ba0d6e90fc506dc0da1601c9e24583bd1b6565a99af42c946f5"
  license "Apache-2.0"

  depends_on "python@3.14"

  def install
    virtualenv_install_with_resources
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/rr --version")
  end
end
