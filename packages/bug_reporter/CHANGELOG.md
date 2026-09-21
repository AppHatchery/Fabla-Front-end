## 0.2.0

- Screenshot upload: `BugReportService.uploadScreenshot` requests a presigned URL and PUTs the image straight to storage; the report now carries `screenshot.key`. Payload upgraded to schema v1 (`schemaVersion` + `screenshot` object). Falls back to no image when uploads are unavailable, so reports never fail on the screenshot.
- Breadcrumb panel now renders on a `Material` (clears a `ListTile` ink-splash warning).

## 0.1.0

- Initial standalone package.
- `BugReportScope` wrapper installs the capture overlay, tap/lifecycle breadcrumbs, and semantics in one widget.
- `BugReporterConfig` + `BugReporter.init()` for endpoint, API key, report-button visibility, navigator/messenger keys, route-name and icon maps, and a payload scrub hook.
- Optional `BreadcrumbNavigatorObserver` and `BreadcrumbDioInterceptor` add-ons.
