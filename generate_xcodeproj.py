#!/usr/bin/env python3
"""
generate_xcodeproj.py
Generates a minimal Comprehenza.xcodeproj/project.pbxproj
so the project can be opened directly in Xcode.

Run from the project root:
    python3 generate_xcodeproj.py
"""

import os, uuid, hashlib

def uid():
    return hashlib.md5(uuid.uuid4().bytes).hexdigest()[:24].upper()

# ────────────────────────────────────────────────────────────────
# 1. Collect all .swift and .plist source files
# ────────────────────────────────────────────────────────────────
ROOT = os.path.dirname(os.path.abspath(__file__))
SRC  = os.path.join(ROOT, "Comprehenza")

source_files = []
for dirpath, dirnames, filenames in os.walk(SRC):
    dirnames.sort()
    for fn in sorted(filenames):
        if fn.endswith((".swift", ".plist")):
            full = os.path.join(dirpath, fn)
            source_files.append(full)

print(f"Found {len(source_files)} source files.")

# ────────────────────────────────────────────────────────────────
# 2. Assign stable UUIDs to every file
# ────────────────────────────────────────────────────────────────
file_ref_ids  = {}   # path -> PBXFileReference id
build_file_ids = {}  # path -> PBXBuildFile id

for f in source_files:
    file_ref_ids[f]   = uid()
    build_file_ids[f] = uid()

# Special IDs
MAIN_GROUP_ID   = uid()
SRC_GROUP_ID    = uid()
PRODUCTS_ID     = uid()
APP_TARGET_ID   = uid()
BUILD_PHASE_SRC = uid()
BUILD_PHASE_RES = uid()
BUILD_PHASE_FWK = uid()
PROJ_ID         = uid()
CONFIG_LIST_ID  = uid()
TARGET_CFG_LIST = uid()
DEBUG_CFG_ID    = uid()
RELEASE_CFG_ID  = uid()
TARGET_DEBUG_ID = uid()
TARGET_REL_ID   = uid()
PRODUCT_REF_ID  = uid()

# Assets.xcassets
ASSETS_FOLDER   = os.path.join(SRC, "Assets.xcassets")
ASSETS_REF_ID   = uid()
ASSETS_BUILD_ID = uid()

# ────────────────────────────────────────────────────────────────
# 3. Build groups mirroring the folder hierarchy
# ────────────────────────────────────────────────────────────────
# Map group path -> list of (kind, name, ref_id)
# kind: "file" | "group"
group_ids   = {}  # folder path -> group id
group_files = {}  # folder path -> [file paths]
group_children_groups = {}  # folder path -> [child folder paths]

for f in source_files:
    d = os.path.dirname(f)
    if d not in group_files:
        group_files[d] = []
        group_ids[d]   = uid()
    group_files[d].append(f)

# Build parent→children relationship
for d in list(group_ids.keys()):
    parent = os.path.dirname(d)
    if parent != d and parent not in group_children_groups:
        group_children_groups[parent] = []
    if parent != d:
        if d not in group_children_groups.get(parent, []):
            group_children_groups.setdefault(parent, []).append(d)

group_ids[SRC] = SRC_GROUP_ID  # ensure the root Comprehenza folder has our fixed id

def pbx_file_ref(fpath):
    rel = os.path.relpath(fpath, ROOT)
    fid = file_ref_ids[fpath]
    ext = os.path.splitext(fpath)[1]
    ftype = "sourcecode.swift" if ext == ".swift" else "text.plist.xml"
    name = os.path.basename(fpath)
    return f'\t\t{fid} = {{isa = PBXFileReference; lastKnownFileType = {ftype}; name = "{name}"; path = "{rel}"; sourceTree = SOURCE_ROOT; }};\n'

def pbx_build_file(fpath):
    bid = build_file_ids[fpath]
    fid = file_ref_ids[fpath]
    return f'\t\t{bid} = {{isa = PBXBuildFile; fileRef = {fid}; }};\n'

def pbx_group(gpath):
    gid = group_ids[gpath]
    name = os.path.basename(gpath)
    children = ""
    # sub-groups
    for cg in sorted(group_children_groups.get(gpath, [])):
        children += f"\t\t\t\t{group_ids[cg]},\n"
    # files
    for f in sorted(group_files.get(gpath, [])):
        children += f"\t\t\t\t{file_ref_ids[f]},\n"
    return (
        f'\t\t{gid} = {{\n'
        f'\t\t\tisa = PBXGroup;\n'
        f'\t\t\tchildren = (\n{children}\t\t\t);\n'
        f'\t\t\tpath = "{name}";\n'
        f'\t\t\tsourceTree = "<group>";\n'
        f'\t\t}};\n'
    )

# ────────────────────────────────────────────────────────────────
# 4. Build sources phase (only .swift)
# ────────────────────────────────────────────────────────────────
swift_files = [f for f in source_files if f.endswith(".swift")]

sources_phase = ""
for f in swift_files:
    sources_phase += f"\t\t\t\t{build_file_ids[f]},\n"

# ────────────────────────────────────────────────────────────────
# 5. Assemble pbxproj
# ────────────────────────────────────────────────────────────────
file_refs_section = "".join(pbx_file_ref(f) for f in source_files)
# Add Assets.xcassets as a folder-type file reference
assets_rel = os.path.relpath(ASSETS_FOLDER, ROOT)
file_refs_section += f'\t\t{ASSETS_REF_ID} = {{isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; name = "Assets.xcassets"; path = "{assets_rel}"; sourceTree = SOURCE_ROOT; }};\n'

build_files_section = "".join(pbx_build_file(f) for f in swift_files)
# Build file entry for the assets catalog (goes into resources phase)
build_files_section += f'\t\t{ASSETS_BUILD_ID} = {{isa = PBXBuildFile; fileRef = {ASSETS_REF_ID}; }};\n'

groups_section = ""
# Root main group
root_children = f"\t\t\t\t{SRC_GROUP_ID},\n\t\t\t\t{PRODUCTS_ID},\n"
groups_section += (
    f'\t\t{MAIN_GROUP_ID} = {{\n'
    f'\t\t\tisa = PBXGroup;\n'
    f'\t\t\tchildren = (\n{root_children}\t\t\t);\n'
    f'\t\t\tsourceTree = "<group>";\n'
    f'\t\t}};\n'
)
# Products group
groups_section += (
    f'\t\t{PRODUCTS_ID} = {{\n'
    f'\t\t\tisa = PBXGroup;\n'
    f'\t\t\tchildren = (\n\t\t\t\t{PRODUCT_REF_ID},\n\t\t\t);\n'
    f'\t\t\tname = Products;\n'
    f'\t\t\tsourceTree = "<group>";\n'
    f'\t\t}};\n'
)
# All source groups
all_dirs = sorted(group_ids.keys())
for gpath in all_dirs:
    groups_section += pbx_group(gpath)

# Inject Assets.xcassets ref into the Comprehenza source group
# Find the SRC group and add the assets ref to its children
import re as _re
_assets_child = f"\t\t\t\t{ASSETS_REF_ID},\n"
_src_group_pattern = f"{SRC_GROUP_ID} = {{\\n\\t\\t\\tisa = PBXGroup;\\n\\t\\t\\tchildren = \\(\\n"
_match = _re.search(_src_group_pattern, groups_section)
if _match:
    insert_pos = _match.end()
    groups_section = groups_section[:insert_pos] + _assets_child + groups_section[insert_pos:]

pbxproj = f'''// !$*UTF8*$!
{{
\tarchiveVersion = 1;
\tclasses = {{}};
\tobjectVersion = 56;
\tobjects = {{

/* Begin PBXBuildFile section */
{build_files_section}/* End PBXBuildFile section */

/* Begin PBXFileReference section */
\t\t{PRODUCT_REF_ID} = {{isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = Comprehenza.app; sourceTree = BUILT_PRODUCTS_DIR; }};
{file_refs_section}/* End PBXFileReference section */

/* Begin PBXFrameworksBuildPhase section */
\t\t{BUILD_PHASE_FWK} = {{
\t\t\tisa = PBXFrameworksBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXFrameworksBuildPhase section */

/* Begin PBXGroup section */
{groups_section}/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{APP_TARGET_ID} = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {TARGET_CFG_LIST};
\t\t\tbuildPhases = (
\t\t\t\t{BUILD_PHASE_SRC},
\t\t\t\t{BUILD_PHASE_FWK},
\t\t\t\t{BUILD_PHASE_RES},
\t\t\t);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = Comprehenza;
\t\t\tproductName = Comprehenza;
\t\t\tproductReference = {PRODUCT_REF_ID};
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{PROJ_ID} = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{
\t\t\t\tLastUpgradeCheck = 1500;
\t\t\t\tTargetAttributes = {{
\t\t\t\t\t{APP_TARGET_ID} = {{
\t\t\t\t\t\tCreatedOnToolsVersion = 15.0;
\t\t\t\t\t}};
\t\t\t\t}};
\t\t\t}};
\t\t\tbuildConfigurationList = {CONFIG_LIST_ID};
\t\t\tcompatibilityVersion = "Xcode 14.0";
\t\t\tdevelopmentRegion = en;
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, Base);
\t\t\tmainGroup = {MAIN_GROUP_ID};
\t\t\tproductRefGroup = {PRODUCTS_ID};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = ({APP_TARGET_ID});
\t\t}};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
\t\t{BUILD_PHASE_RES} = {{
\t\t\tisa = PBXResourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
\t\t\t\t{ASSETS_BUILD_ID},
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{BUILD_PHASE_SRC} = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{sources_phase}\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		{DEBUG_CFG_ID} = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Debug;
		}};
		{RELEASE_CFG_ID} = {{
			isa = XCBuildConfiguration;
			buildSettings = {{
				ALWAYS_SEARCH_USER_PATHS = NO;
				IPHONEOS_DEPLOYMENT_TARGET = 16.0;
				SDKROOT = iphoneos;
				SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
				SWIFT_VERSION = 5.9;
				TARGETED_DEVICE_FAMILY = 1;
			}};
			name = Release;
		}};
\t\t{TARGET_DEBUG_ID} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Comprehenza/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.comprehenza.app;
\t\t\t\tPRODUCT_NAME = Comprehenza;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.9;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Debug;
\t\t}};
\t\t{TARGET_REL_ID} = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{
\t\t\t\tASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
\t\t\t\tCODE_SIGN_STYLE = Automatic;
\t\t\t\tCURRENT_PROJECT_VERSION = 1;
\t\t\t\tGENERATE_INFOPLIST_FILE = NO;
\t\t\t\tINFOPLIST_FILE = Comprehenza/Info.plist;
\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 16.0;
\t\t\t\tMARKETING_VERSION = 1.0;
\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = com.comprehenza.app;
\t\t\t\tPRODUCT_NAME = Comprehenza;
\t\t\t\tSWIFT_EMIT_LOC_STRINGS = YES;
\t\t\t\tSWIFT_VERSION = 5.9;
\t\t\t\tTARGETED_DEVICE_FAMILY = 1;
\t\t\t}};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{CONFIG_LIST_ID} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({DEBUG_CFG_ID}, {RELEASE_CFG_ID});
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
\t\t{TARGET_CFG_LIST} = {{
\t\t\tisa = XCConfigurationList;
\t\t\tbuildConfigurations = ({TARGET_DEBUG_ID}, {TARGET_REL_ID});
\t\t\tdefaultConfigurationIsVisible = 0;
\t\t\tdefaultConfigurationName = Release;
\t\t}};
/* End XCConfigurationList section */

\t}};
\trootObject = {PROJ_ID};
}}
'''

# ────────────────────────────────────────────────────────────────
# 6. Write the .xcodeproj
# ────────────────────────────────────────────────────────────────
proj_dir = os.path.join(ROOT, "Comprehenza.xcodeproj")
os.makedirs(proj_dir, exist_ok=True)
out_path = os.path.join(proj_dir, "project.pbxproj")
with open(out_path, "w") as f:
    f.write(pbxproj)

print(f"✅ Generated {out_path}")
print("   Open Comprehenza.xcodeproj in Xcode to build & run.")
