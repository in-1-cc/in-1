(() => {
  "use strict";

  const container = document.querySelector("[data-installables-table]");
  if (!container) return;

  const table = container.querySelector("table");
  const body = table.tBodies[0];
  const buttons = Array.from(table.querySelectorAll("button[data-sort-key]"));
  const columns = {
    name: 1,
    version: 2,
    date: 3,
    by: 4,
    type: 5,
    completion: 6,
    man: 7,
    description: 8,
  };
  const collator = new Intl.Collator(undefined, {
    numeric: true,
    sensitivity: "base",
  });

  function requestedSort() {
    const params = new URLSearchParams(window.location.search);
    const key = params.get("sort");
    const column = columns[key] || columns.name;
    const direction = params.get("order") === "desc" ? "desc" : "asc";
    return {
      column,
      direction,
    };
  }

  function sortTable(column, direction, updateUrl) {
    const multiplier = direction === "desc" ? -1 : 1;
    const rows = Array.from(body.rows);
    rows.sort((left, right) => {
      const a = left.cells[column].dataset.sortValue;
      const b = right.cells[column].dataset.sortValue;
      return collator.compare(a, b) * multiplier;
    });
    rows.forEach((row, index) => {
      body.appendChild(row);
      row.querySelector(".installable-order strong").textContent = index + 1;
    });

    buttons.forEach((button) => {
      const header = button.closest("th");
      const active = header.cellIndex === column;
      header.setAttribute(
        "aria-sort",
        active ? (direction === "asc" ? "ascending" : "descending") : "none"
      );
      const marker = header.querySelector(".sort-marker");
      marker.textContent = active ? (direction === "asc" ? "▲" : "▼") : "↕";
    });

    if (updateUrl) {
      const url = new URL(window.location.href);
      const key = Object.keys(columns).find((name) => columns[name] === column);
      url.searchParams.set("sort", key);
      url.searchParams.set("order", direction);
      window.history.replaceState(null, "", url);
    }
  }

  let state = requestedSort();
  sortTable(state.column, state.direction, false);

  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      const column = columns[button.dataset.sortKey];
      let direction;
      if (state.column === column) {
        direction = state.direction === "asc" ? "desc" : "asc";
      } else {
        direction = column === columns.date ||
          column === columns.completion || column === columns.man
          ? "desc"
          : "asc";
      }
      state = {column, direction};
      sortTable(column, direction, true);
    });
  });

  const tooltip = document.createElement("div");
  tooltip.className = "installables-header-tooltip";
  tooltip.setAttribute("role", "tooltip");
  tooltip.hidden = true;
  document.body.appendChild(tooltip);

  function showTooltip(button) {
    tooltip.textContent = button.dataset.tooltip;
    tooltip.hidden = false;
    const rect = button.getBoundingClientRect();
    tooltip.style.left = `${rect.left + rect.width / 2}px`;
    tooltip.style.top = `${rect.top - tooltip.offsetHeight - 8}px`;
  }

  function hideTooltip() {
    tooltip.hidden = true;
  }

  buttons.filter((button) => button.dataset.tooltip).forEach((button) => {
    button.addEventListener("mouseenter", () => showTooltip(button));
    button.addEventListener("mouseleave", hideTooltip);
    button.addEventListener("focus", () => showTooltip(button));
    button.addEventListener("blur", hideTooltip);
  });

  window.addEventListener("scroll", hideTooltip, true);
  window.addEventListener("resize", hideTooltip);
})();
