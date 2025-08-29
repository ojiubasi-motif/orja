/* eslint-disable no-unused-vars */
// import { AlignRight, ChevronDown, RefreshCw, Search } from "react-feather";
import { Link, NavLink } from "react-router-dom";
import User from "../../../public/img/user.png";
import { Search } from "react-feather";
// import { Printer } from "react-feather";

const Topnav = () => {
  return (
    <div className="display-flex px-2 py-1">
      {/* ========logo======= */}
      

      {/* ========search========= */}
      <div className="d-flex align-items-center p-2 border border-primary border-2 rounded w-50" style={{backgroundColor:"transparent"}}>
          <input
            type="text"
            className=" text-dark"
            style={{backgroundColor:"inherit",border:"none", outline:"none", width:"95%"}}
            placeholder="search for student or school"
          />
          <Search size={16} className=" text-primary" />
        </div>

      {/* =========user profile========== */}
      <div className="dropdown">
        <div
          className="user-profile p-3  d-flex align-items-center justify-content-between dropdown-toggle"
          data-bs-toggle="dropdown"
          aria-expanded="false"
          style={{ cursor: "pointer", height: "60px" }}
        >
          <img
            src={User}
            alt="user-avatar"
            className="rounded"
            style={{ width: "35px", height: "35px", objectFit: "contain" }}
          />
        </div>
        <ul className="dropdown-menu ms-2">
          <li>
            <a className="dropdown-item" href="#">
              Action
            </a>
          </li>
          <li>
            <a className="dropdown-item" href="#">
              Another action
            </a>
          </li>
          <li>
            <a className="dropdown-item" href="#">
              Something else here
            </a>
          </li>
        </ul>
      </div>
    </div>
  );
};

export default Topnav;